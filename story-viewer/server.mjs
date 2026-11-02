// Story viewer: reads an initiative's Stories.md, Opgaver.md and START-HER.md and joins them with live tracker data
// (Azure DevOps or GitHub, picked per story from its link; see providers/).
// Usage: node server.mjs [--vault <path>] [--port 4710] [--no-open]   then open http://localhost:4710
// The vault is --vault, else $STORY_VIEWER_VAULT, else the current directory. Initiatives live in <vault>/AI/<Folder>/.
import { createServer } from 'node:http';
import { readFile, readdir, access, writeFile, mkdir, rename } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import { promisify } from 'node:util';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as ado from './providers/ado.mjs';
import * as github from './providers/github.mjs';

const execFileAsync = promisify(execFile);
const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const arg = (name) => (args.includes(name) ? args[args.indexOf(name) + 1] : undefined);
const port = Number(arg('--port')) || 4710;
const vaultRoot = path.resolve(arg('--vault') ?? process.env.STORY_VIEWER_VAULT ?? process.cwd());
const vaultName = path.basename(vaultRoot);
// Initiative folders live under AI/ (see the vault AGENTS.md).
const projectsDir = 'AI';
const projectsRoot = path.join(vaultRoot, projectsDir);
if (!existsSync(projectsRoot)) {
	console.error(`No ${projectsDir}/ folder in ${vaultRoot}. Pass --vault <path>, set STORY_VIEWER_VAULT or run from the vault.`);
	process.exit(1);
}

const providers = [ado, github];

// A tracker link in markdown, [label](url), resolved to its provider: { provider, ref }.
function refIn(text) {
	for (const m of String(text ?? '').matchAll(/\[[^\]]*\]\((https?:\/\/[^)\s]+)\)/g)) {
		for (const provider of providers) {
			const ref = provider.parseRef(m[1]);
			if (ref) return { provider, ref };
		}
	}
	return null;
}

// Filled only by a manual fetch (page load or Refresh); polling reads these caches and never calls a tracker.
const itemCache = new Map(); // story id → { at, item }
const prCache = new Map(); // story id → PR or null

async function fetchItems(links, force) {
	const now = Date.now();
	const errors = [];
	if (force) {
		await Promise.all(providers.map(async (provider) => {
			const refs = links.filter((l) => l.provider === provider).map((l) => l.ref);
			if (!refs.length) return;
			try {
				for (const [id, item] of await provider.fetchItems(refs)) itemCache.set(id, { at: now, item });
			} catch (err) {
				errors.push(err.message);
			}
		}));
	}
	const items = Object.fromEntries(links.filter((l) => itemCache.has(l.ref.id)).map((l) => {
		const { _github, ...item } = itemCache.get(l.ref.id).item;
		return [l.ref.id, item];
	}));
	return { items, error: errors.join('; ') || null };
}

// A story's PR, found by branch: the Branch / worktree cell holds `branch` and `C:\worktree`; the worktree's origin
// tells which tracker and repo to ask. Stories without a worktree on this machine get no PR.
function branchAndWorktree(cell) {
	const spans = [...String(cell).matchAll(/`([^`]+)`/g)].map((m) => m[1].trim());
	const isPath = (s) => /^([A-Za-z]:[\\/]|~|\/)/.test(s);
	return { branch: spans.find((s) => !isPath(s)) ?? null, worktree: spans.find(isPath) ?? null };
}

// A worktree's origin, cached per folder: it doesn't change, and the 10 s poll would otherwise spawn git every time.
const remoteCache = new Map();
async function remoteOf(story) {
	const { branch, worktree } = branchAndWorktree(story.branch);
	if (!worktree) return null;
	const dir = worktree.replace(/^~/, process.env.USERPROFILE ?? process.env.HOME ?? '~');
	if (!remoteCache.has(dir)) {
		if (!existsSync(dir)) return null;
		const { stdout } = await execFileAsync('git', ['-C', dir, 'remote', 'get-url', 'origin'], { windowsHide: true });
		const url = stdout.trim();
		const match = providers.map((provider) => ({ provider, remote: provider.parseRemote(url) })).find((m) => m.remote);
		// Unknown hosts still get a name: the last path segment of the URL.
		const name = match?.remote.repo ?? url.replace(/\.git$/, '').split(/[/:]/).at(-1);
		remoteCache.set(dir, { name, provider: match?.provider ?? null, remote: match?.remote ?? null });
	}
	return { branch, ...remoteCache.get(dir) };
}

async function findPr(story) {
	const origin = await remoteOf(story);
	if (!origin?.branch || !origin.provider) return null;
	return origin.provider.findPr(origin.remote, origin.branch);
}

async function repoNames(stories) {
	const entries = await Promise.all(stories.filter((s) => s.id).map(async (s) => {
		try {
			return [s.id, (await remoteOf(s))?.name ?? null];
		} catch {
			return [s.id, null];
		}
	}));
	return Object.fromEntries(entries.filter(([, name]) => name));
}

async function fetchPrs(stories, force) {
	if (force) {
		await Promise.all(stories.filter((s) => s.id && !s.removed).map(async (s) => {
			try {
				prCache.set(s.id, await findPr(s));
			} catch {
				prCache.delete(s.id);
			}
		}));
	}
	return Object.fromEntries(stories.filter((s) => prCache.get(s.id)).map((s) => [s.id, prCache.get(s.id)]));
}

const lines = (text) => text.replace(/\r\n/g, '\n').split('\n');
// Depends on may use the short name, without a trailing "(…)".
const shortName = (name) => name.replace(/\s*\([^)]*\)\s*$/, '');
// Stories and Opgaver sections without a tracker link are matched by name instead.
const localId = (name) => `local:${shortName(name)}`;
const tableCells = (row) => row.trim().replace(/^\||\|$/g, '').split('|');

function sections(text) {
	const result = [];
	let current = { heading: '', start: 0, body: [] };
	lines(text).forEach((line, i) => {
		if (line.startsWith('## ')) {
			result.push(current);
			current = { heading: line.slice(3).trim(), start: i + 1, body: [] };
		} else {
			current.body.push(line);
		}
	});
	result.push(current);
	return result;
}

// Bullets with their indented continuation lines joined. `line` is the 0-based line in the file, `raw` its text.
function bullets(body, start = 0) {
	const items = [];
	for (const [i, line] of body.entries()) {
		const m = line.match(/^(\s*)- (.*)$/);
		if (m) items.push({ indent: Math.floor(m[1].replace(/\t/g, '  ').length / 2), text: m[2], line: start + i, raw: line });
		else if (items.length && /^\s+\S/.test(line)) items.at(-1).text += ' ' + line.trim();
		else if (!line.trim()) items.push(null);
	}
	return items.filter(Boolean);
}

// The tracker column is called ADO or Issue.
const trackerColumn = (header) => {
	const i = header.findIndex((h) => h.startsWith('ado'));
	return i >= 0 ? i : header.findIndex((h) => h.startsWith('issue'));
};

function parseStories(text) {
	const all = lines(text);
	const featureLine = all.find((l) => /feature/i.test(l) && refIn(l));
	const rows = all.filter((l) => l.trim().startsWith('|'));
	const feature = featureLine ? refIn(featureLine) : null;
	if (rows.length < 2) return { feature, stories: [] };
	const cells = (row) => tableCells(row).map((c) => c.trim());
	const header = cells(rows[0]).map((h) => h.toLowerCase());
	const col = (name) => header.findIndex((h) => h.startsWith(name));
	const stories = rows.slice(2).map((row) => {
		const c = cells(row);
		const rawName = c[col('story')] ?? '';
		const state = c[col('state')] ?? '';
		const link = refIn(c[trackerColumn(header)] ?? '');
		const name = rawName.replace(/~~/g, '');
		return {
			order: c[col('#')] ?? '',
			name,
			id: link?.ref.id ?? localId(name),
			local: !link,
			link,
			noteState: state,
			removed: /removed/i.test(state) || rawName.startsWith('~~'),
			dependsOn: c[col('depends')] ?? '',
			branch: c[col('branch')] ?? '',
		};
	});
	for (const s of stories) {
		s.deps = s.removed
			? []
			: stories
					.filter((o) => o !== s && !o.removed && s.dependsOn.includes(shortName(o.name)))
					.map((o) => o.id);
	}
	return { feature, stories };
}

// Tasks above the first heading form a "General" section.
function parseOpgaver(text) {
	return sections(text)
		.map((s) => ({
			heading: s.heading || 'General',
			id: refIn(s.body.join('\n'))?.ref.id ?? localId(s.heading || 'General'),
			intro: s.body.find((l) => l.trim() && !/^\s*- /.test(l) && !l.startsWith('# '))?.trim() ?? '',
			items: bullets(s.body, s.start).map((b) => {
				const task = b.text.match(/^\[( |x|X)\] (.*)$/);
				return task ? { ...b, task: true, done: task[1] !== ' ', text: task[2] } : { ...b, task: false };
			}),
		}))
		.filter((s, i) => i > 0 || s.items.some((item) => item.task));
}

// Without a Stories.md, each Opgaver section is a story; its state follows its ticks.
function storiesFromOpgaver(opgaver) {
	return opgaver.map((section, i) => {
		const tasks = section.items.filter((item) => item.task);
		const done = tasks.filter((t) => t.done).length;
		return {
			order: String(i + 1),
			name: section.heading,
			id: section.id,
			local: true,
			noteState: tasks.length && done === tasks.length ? 'Done' : done ? 'Active' : 'New',
			removed: false,
			deps: [],
			branch: '',
		};
	});
}

function parseStartHer(text) {
	const secs = sections(text);
	const find = (name) => secs.find((s) => s.heading.toLowerCase().startsWith(name))?.body ?? [];
	const decisions = bullets(find('beslutninger'))
		.filter((b) => b.indent === 0)
		.map((b) => {
			const m = b.text.match(/^(\d{4}-\d{2}-\d{2})\s*\(([^)]*)\):\s*([\s\S]*)$/);
			if (!m) return { date: '', tags: [], text: b.text };
			return { date: m[1], tags: m[2].split(' / ').map((t) => t.split(',')[0].trim()), text: m[3] };
		});
	const introLines = [];
	for (const line of secs[0].body.filter((l) => !l.startsWith('# '))) {
		if (!line.trim()) {
			if (introLines.length) break;
			continue;
		}
		introLines.push(line.trim());
	}
	return {
		intro: introLines.join(' '),
		openQuestions: bullets(find('åbne spørgsmål')).map((b) => b.text),
		status: bullets(find('status')).map((b) => b.text),
		decisions,
	};
}

async function readText(file) {
	try {
		return await readFile(file, 'utf8');
	} catch {
		return '';
	}
}

const exists = (file) => access(file).then(() => true, () => false);
// Finished initiatives are moved here (vault AI/AGENTS.md); they are listed as "<archiveDir>/<Folder>".
const archiveDir = '_Archive';

// Initiatives with a Stories.md, or at least an Opgaver.md (then without tracker data).
async function initiativesIn(dir, prefix = '') {
	const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
	const result = [];
	for (const e of entries.filter((d) => d.isDirectory() && !/^[._]/.test(d.name))) {
		const sub = path.join(dir, e.name);
		if ((await exists(path.join(sub, 'Stories.md'))) || (await exists(path.join(sub, 'Opgaver.md')))) result.push(prefix + e.name);
	}
	return result;
}

async function listProjects() {
	return {
		active: await initiativesIn(projectsRoot),
		archived: await initiativesIn(path.join(projectsRoot, archiveDir), `${archiveDir}/`),
	};
}

const isProject = async (folder) => {
	const { active, archived } = await listProjects();
	return active.includes(folder) || archived.includes(folder);
};

// Which tracker a project's stories link to, for the colored dot on its button: ado, github, mixed or native (no tracker).
async function trackerKind(folder) {
	const storiesMd = await readText(path.join(projectsRoot, folder, 'Stories.md'));
	if (!storiesMd) return 'native';
	const { feature, stories } = parseStories(storiesMd);
	const names = new Set([feature, ...stories.map((s) => s.link)].filter(Boolean).map((l) => l.provider.name));
	return names.size === 0 ? 'native' : names.size > 1 ? 'mixed' : [...names][0];
}

async function listProjectsWithKinds() {
	const projects = await listProjects();
	const all = [...projects.active, ...projects.archived];
	const kinds = Object.fromEntries(await Promise.all(all.map(async (p) => [p, await trackerKind(p)])));
	return { ...projects, kinds };
}

async function loadProject(folder, force) {
	if (!(await isProject(folder))) throw new Error(`No Stories.md or Opgaver.md in ${folder}`);
	const dir = path.join(projectsRoot, folder);
	const [storiesMd, opgaverMd, startMd, nextMd] = await Promise.all([
		readText(path.join(dir, 'Stories.md')),
		readText(path.join(dir, 'Opgaver.md')),
		readText(path.join(dir, 'START-HER.md')),
		readText(path.join(vaultRoot, '01 - Next Actions.md')),
	]);
	const hasStories = await exists(path.join(dir, 'Stories.md'));
	const opgaver = parseOpgaver(opgaverMd);
	const { feature, stories } = hasStories ? parseStories(storiesMd) : { feature: null, stories: storiesFromOpgaver(opgaver) };
	const links = [feature, ...stories.map((s) => s.link)].filter(Boolean);
	const [{ items, error }, prs, repos] = await Promise.all([fetchItems(links, force), fetchPrs(stories, force), repoNames(stories)]);
	const fetched = links.map((l) => itemCache.get(l.ref.id)?.at).filter(Boolean);
	return {
		folder,
		notePath: `${projectsDir}/${folder}`,
		vaultName,
		hasStories,
		featureId: feature?.ref.id ?? null,
		trackers: [...new Set(links.map((l) => l.provider.name))],
		stories: stories.map(({ link, ...s }) => s),
		opgaver,
		startHer: parseStartHer(startMd),
		nextActions: bullets(lines(nextMd)).filter((b) => b.text.includes(`${folder}/`)).map((b) => b.text),
		items,
		prs,
		repos,
		fetchError: error,
		fetchedAt: fetched.length ? new Date(Math.min(...fetched)).toISOString() : null,
		loadedAt: new Date().toISOString(),
	};
}

const httpError = (status, message) => Object.assign(new Error(message), { status });

async function storyIn(folder, id) {
	if (!(await isProject(folder)) || !(await exists(path.join(projectsRoot, folder, 'Stories.md')))) throw httpError(404, `No Stories.md in ${folder}`);
	const file = path.join(projectsRoot, folder, 'Stories.md');
	const story = parseStories(await readFile(file, 'utf8')).stories.find((s) => s.id === id);
	if (typeof id !== 'string' || !story?.link) throw httpError(400, `${id} is not a story in ${folder}`);
	const item = itemCache.get(id)?.item;
	if (!item) throw httpError(409, 'Fetch from the tracker first');
	return { file, story, item };
}

async function storyStates(folder, id) {
	const { story, item } = await storyIn(folder, id);
	try {
		return await story.link.provider.states(story.link.ref, item);
	} catch (err) {
		throw httpError(502, `Could not read states: ${err.message}`);
	}
}

// The only tracker write: set State on a story listed in <folder>/Stories.md, then mirror it in that table.
async function setState(folder, id, state) {
	const { file, story, item } = await storyIn(folder, id);
	if (typeof state !== 'string' || !(await storyStates(folder, id)).includes(state)) throw httpError(400, `${item.type} has no state "${state}"`);
	try {
		item.state = await story.link.provider.setState(story.link.ref, item, state);
	} catch (err) {
		throw httpError(502, `Update failed: ${err.message}`);
	}
	await writeStoryState(file, id, item.state);
	return item.state;
}

// Rewrites the State cell of the story's row; Removed also strikes the name through (vault AGENTS.md rule).
async function writeStoryState(file, id, state) {
	const text = await readFile(file, 'utf8');
	const all = text.split(/\r?\n/);
	const header = all.find((l) => l.trim().startsWith('|'));
	if (!header) return;
	const names = tableCells(header).map((c) => c.trim().toLowerCase());
	const stateCol = names.findIndex((h) => h.startsWith('state'));
	const storyCol = names.findIndex((h) => h.startsWith('story'));
	const linkCol = trackerColumn(names);
	const index = all.findIndex((l) => l.trim().startsWith('|') && refIn(tableCells(l)[linkCol])?.ref.id === id);
	if (index < 0 || stateCol < 0) return;
	const line = all[index];
	const lead = line.match(/^\s*/)[0];
	const cells = tableCells(line);
	const setCell = (i, value) => {
		const [, before, , after] = cells[i].match(/^(\s*)(.*?)(\s*)$/);
		cells[i] = `${before || ' '}${value}${after || ' '}`;
	};
	setCell(stateCol, state);
	if (storyCol >= 0) {
		const name = cells[storyCol].trim().replace(/^~~|~~$/g, '');
		setCell(storyCol, state === 'Removed' ? `~~${name}~~` : name);
	}
	all[index] = `${lead}|${cells.join('|')}|`;
	await writeFile(file, all.join(text.includes('\r\n') ? '\r\n' : '\n'));
}

// Vault write besides the State cell and archiving: tick or untick one task in <folder>/Opgaver.md, and only if that line
// is unchanged since the page loaded. Unticking also drops the trailing "✅ <date>" that ticking added.
async function tickTask(folder, lineNo, raw) {
	if (!(await isProject(folder))) throw httpError(404, `No Stories.md or Opgaver.md in ${folder}`);
	const file = path.join(projectsRoot, folder, 'Opgaver.md');
	const text = await readFile(file, 'utf8');
	const all = text.split(/\r?\n/);
	if (!Number.isInteger(lineNo) || typeof raw !== 'string' || all[lineNo] !== raw || !/^\s*- \[[ xX]\] /.test(raw)) {
		throw httpError(409, 'The task changed since the page loaded; reload and try again');
	}
	if (/^\s*- \[ \] /.test(raw)) {
		const today = new Date().toLocaleDateString('sv-SE');
		all[lineNo] = `${raw.replace('- [ ] ', '- [x] ').trimEnd()} ✅ ${today}`;
	} else {
		all[lineNo] = raw.replace(/- \[[xX]\] /, '- [ ] ').replace(/\s*✅ \d{4}-\d{2}-\d{2}\s*$/, '');
	}
	await writeFile(file, all.join(text.includes('\r\n') ? '\r\n' : '\n'));
}

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const joinLike = (text, all) => all.join(text.includes('\r\n') ? '\r\n' : '\n');

// Markdown notes in the vault, skipping tooling folders (.obsidian, .git, .trash).
async function vaultNotes(dir = vaultRoot) {
	const result = [];
	for (const e of await readdir(dir, { withFileTypes: true })) {
		if (e.name.startsWith('.')) continue;
		const full = path.join(dir, e.name);
		if (e.isDirectory()) result.push(...(await vaultNotes(full)));
		else if (e.name.endsWith('.md')) result.push(full);
	}
	return result;
}

// Archiving clears the initiative from the shared GTD notes (vault AI/AGENTS.md): every "## " section of
// 04 - Projects.md and every Next Actions bullet (with its indented continuation lines) that links into the folder.
async function removeFromSharedNotes(ref) {
	const removed = [];
	const projectsFile = path.join(vaultRoot, '04 - Projects.md');
	const projectsText = await readText(projectsFile);
	if (projectsText) {
		const all = projectsText.split(/\r?\n/);
		const keep = [];
		for (let i = 0; i < all.length; ) {
			let end = i + 1;
			if (all[i].startsWith('## ')) while (end < all.length && !/^#{1,2} /.test(all[end])) end++;
			const block = all.slice(i, end);
			if (all[i].startsWith('## ') && block.some((l) => l.includes(ref))) removed.push(`04 - Projects: ${all[i]}`);
			else keep.push(...block);
			i = end;
		}
		if (keep.length !== all.length) await writeFile(projectsFile, joinLike(projectsText, keep));
	}
	const nextFile = path.join(vaultRoot, '01 - Next Actions.md');
	const nextText = await readText(nextFile);
	if (nextText) {
		const all = nextText.split(/\r?\n/);
		const keep = [];
		for (let i = 0; i < all.length; ) {
			const bullet = all[i].match(/^(\s*)- /);
			let end = i + 1;
			if (bullet) while (end < all.length && all[end].trim() && all[end].match(/^\s*/)[0].length > bullet[1].length) end++;
			const block = all.slice(i, end);
			if (bullet && block.some((l) => l.includes(ref))) removed.push(`01 - Next Actions: ${all[i].trim()}`);
			else keep.push(...block);
			i = end;
		}
		if (keep.length !== all.length) await writeFile(nextFile, joinLike(nextText, keep));
	}
	return removed;
}

// Moves an initiative to AI/_Archive/ or back, then rewrites [[AI/<Folder>/…]] and ](AI/<Folder>/…) links in every note.
// Archiving also clears it from 04 - Projects and Next Actions; unarchiving doesn't restore those.
async function moveProject(folder, archive) {
	const { active, archived } = await listProjects();
	if (!(archive ? active : archived).includes(folder)) throw httpError(404, `${folder} is not ${archive ? 'an active' : 'an archived'} initiative`);
	const target = archive ? `${archiveDir}/${folder}` : folder.slice(archiveDir.length + 1);
	const from = `${projectsDir}/${folder}`;
	const to = `${projectsDir}/${target}`;
	if (await exists(path.join(vaultRoot, to))) throw httpError(409, `${to} already exists`);
	await mkdir(path.join(projectsRoot, archiveDir), { recursive: true });
	try {
		await rename(path.join(vaultRoot, from), path.join(vaultRoot, to));
	} catch (err) {
		throw httpError(409, `Could not move ${from} (${err.code ?? err.message}); is a file in it open?`);
	}
	const removed = archive ? await removeFromSharedNotes(`${from}/`) : [];
	const link = new RegExp(`(\\[\\[|\\]\\()${escapeRe(from)}/`, 'g');
	const relinked = [];
	for (const file of await vaultNotes()) {
		const text = await readFile(file, 'utf8');
		const updated = text.replace(link, `$1${to}/`);
		if (updated === text) continue;
		await writeFile(file, updated);
		relinked.push(path.relative(vaultRoot, file));
	}
	return { folder: target, removed, relinked };
}

async function readJson(req) {
	let body = '';
	for await (const chunk of req) {
		body += chunk;
		if (body.length > 10_000) throw httpError(413, 'Body too large');
	}
	try {
		return JSON.parse(body);
	} catch {
		throw httpError(400, 'Invalid JSON');
	}
}

// Blocks other web pages (cross-site POST) and DNS rebinding from reaching the write endpoints.
function sameOrigin(req) {
	return trustedHost(req) && req.headers.origin === `http://${req.headers.host}`;
}

// Any site you visit can make your browser call 127.0.0.1, so every request is checked:
// - Host must be ours: blocks DNS rebinding (an attacker's domain pointed at 127.0.0.1) from reading the API.
// - Browsers mark cross-site calls with Sec-Fetch-Site: blocks other sites from triggering tracker fetches.
//   Requests without the header (curl, scripts on this machine) aren't from a web page and are allowed.
function trustedHost(req) {
	return [`localhost:${port}`, `127.0.0.1:${port}`].includes(req.headers.host);
}
function fromOwnPage(req) {
	const site = req.headers['sec-fetch-site'];
	return site === undefined || site === 'same-origin';
}

// The page may only talk to this server, load nothing external, and never be shown inside another site's frame
// (which would allow tricking you into clicking a checkbox).
const securityHeaders = {
	'Content-Security-Policy':
		"default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
	'X-Frame-Options': 'DENY',
	'X-Content-Type-Options': 'nosniff',
	'Referrer-Policy': 'no-referrer',
	'Cross-Origin-Resource-Policy': 'same-origin',
};

const server = createServer(async (req, res) => {
	const send = (status, type, body) => {
		res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store', ...securityHeaders });
		res.end(body);
	};
	try {
		const url = new URL(req.url, 'http://localhost');
		if (!trustedHost(req)) throw httpError(403, 'Unknown host');
		if (url.pathname.startsWith('/api/') && !fromOwnPage(req)) throw httpError(403, 'Cross-site request refused');
		if (url.pathname === '/') return send(200, 'text/html; charset=utf-8', await readFile(path.join(here, 'index.html')));
		if (url.pathname === '/api/projects') return send(200, 'application/json', JSON.stringify(await listProjectsWithKinds()));
		if (url.pathname === '/api/project') {
			const data = await loadProject(url.searchParams.get('name') ?? '', url.searchParams.has('refresh'));
			return send(200, 'application/json', JSON.stringify(data));
		}
		if (url.pathname === '/api/archive' && req.method === 'POST') {
			if (!sameOrigin(req)) throw httpError(403, 'Cross-origin request refused');
			const { name, archive } = await readJson(req);
			if (typeof name !== 'string' || typeof archive !== 'boolean') throw httpError(400, 'Expected { name, archive }');
			return send(200, 'application/json', JSON.stringify(await moveProject(name, archive)));
		}
		if (url.pathname === '/api/tick' && req.method === 'POST') {
			if (!sameOrigin(req)) throw httpError(403, 'Cross-origin request refused');
			const { name, line, raw } = await readJson(req);
			await tickTask(name, line, raw);
			return send(200, 'application/json', JSON.stringify({ ok: true }));
		}
		if (url.pathname === '/api/states') {
			const states = await storyStates(url.searchParams.get('name') ?? '', url.searchParams.get('id') ?? '');
			return send(200, 'application/json', JSON.stringify(states));
		}
		if (url.pathname === '/api/state' && req.method === 'POST') {
			if (!sameOrigin(req)) throw httpError(403, 'Cross-origin request refused');
			const { name, id, state } = await readJson(req);
			return send(200, 'application/json', JSON.stringify({ state: await setState(name, id, state) }));
		}
		send(404, 'text/plain', 'Not found');
	} catch (err) {
		send(err.status ?? 500, 'application/json', JSON.stringify({ error: err.message }));
	}
});

const link = `http://localhost:${port}`;
const openPage = () => {
	if (!args.includes('--no-open')) execFile('cmd', ['/c', 'start', '', link], { windowsHide: true });
};

// Running it twice (herdr pane, AHK hotkey) just reuses the server that is already up.
server.on('error', (err) => {
	if (err.code !== 'EADDRINUSE') throw err;
	console.log(`Story viewer already running on ${link}`);
	openPage();
});

server.listen(port, '127.0.0.1', () => {
	console.log(`Story viewer on ${link} (vault ${vaultRoot})`);
	openPage();
});
