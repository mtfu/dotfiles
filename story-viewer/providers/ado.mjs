// Azure DevOps, through az only (az login + azure-devops extension); no token in this process.
// Reads: `az boards query`, the work item type's states, `az repos pr list`. The one write: State on a work item.
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import { promisify } from 'node:util';
import path from 'node:path';

const execFileAsync = promisify(execFile);

export const name = 'ado';

const fields = [
	'System.Id',
	'System.Title',
	'System.State',
	'System.WorkItemType',
	'System.AssignedTo',
	'System.Description',
	'Microsoft.VSTS.Common.AcceptanceCriteria',
];

// https://dev.azure.com/<org>/<project>/_workitems/edit/<id> → id "<id>"
export function parseRef(url) {
	const m = String(url).match(/^https:\/\/dev\.azure\.com\/([\w.-]+)\/([^/?#]+)\/_workitems\/edit\/(\d+)/);
	if (!m) return null;
	return { id: m[3], org: m[1], project: decodeURIComponent(m[2]), url: m[0] };
}

// git@ssh.dev.azure.com:v3/org/project/repo or https://[user@]dev.azure.com/org/project/_git/repo
export function parseRemote(remote) {
	const m = String(remote).trim().match(/dev\.azure\.com[:/](?:v3\/)?([^/]+)\/([^/]+)\/(?:_git\/)?([^/]+?)(?:\.git)?$/);
	return m ? { org: m[1], project: decodeURIComponent(m[2]), repo: decodeURIComponent(m[3]) } : null;
}

const orgUrl = (org) => `https://dev.azure.com/${org}`;

// Only these az commands may run. Never add another.
const AZ_ALLOWED = [
	['boards', 'query'],
	['devops', 'invoke', '--area', 'wit', '--resource', 'workItemTypeStates'],
	['repos', 'pr', 'list'],
	['boards', 'work-item', 'update'],
];
async function az(azArgs) {
	if (!AZ_ALLOWED.some((prefix) => prefix.every((a, i) => azArgs[i] === a))) throw new Error(`az command not allowed: ${azArgs.slice(0, 3).join(' ')}`);
	if (!azArgs.every((a) => /^[\w\s.,:/\[\]()=-]*$/.test(a))) throw new Error('Unsafe az argument');
	const [file, prefix] = azCommand();
	try {
		const { stdout } = await execFileAsync(file, [...prefix, ...azArgs, '-o', 'json'], { maxBuffer: 20_000_000, windowsHide: true });
		return JSON.parse(stdout);
	} catch (err) {
		throw new Error(`az ${azArgs.slice(0, 2).join(' ')} failed (az login?): ${String(err.stderr ?? '').trim().split('\n').at(-1) || err.message}`);
	}
}

// On Windows az is az.cmd, which runs its bundled Python isolated (-I) so PYTHONIOENCODING is ignored, and it writes cp1252:
// if any field holds a non-cp1252 character, az drops ALL non-ASCII (æøå). Calling that Python directly with -X utf8 fixes
// the encoding and avoids a shell.
function azCommand() {
	if (process.platform !== 'win32') return ['az', []];
	const azCmd = (process.env.PATH ?? '').split(path.delimiter).map((d) => path.join(d, 'az.cmd')).find(existsSync);
	const python = azCmd && path.join(path.dirname(azCmd), '..', 'python.exe');
	if (!python || !existsSync(python)) throw new Error('az CLI not found (expected az.cmd with its bundled python.exe on PATH)');
	return [python, ['-X', 'utf8', '-IBm', 'azure.cli']];
}

// refs from parseRef → Map id → item. One WIQL query per org/project.
export async function fetchItems(refs) {
	const groups = new Map();
	for (const ref of refs) {
		const key = `${ref.org}/${ref.project}`;
		if (!groups.has(key)) groups.set(key, []);
		groups.get(key).push(ref);
	}
	const result = new Map();
	await Promise.all([...groups.values()].map(async (group) => {
		const { org, project } = group[0];
		const wiql = `SELECT ${fields.map((f) => `[${f}]`).join(',')} FROM WorkItems WHERE [System.Id] IN (${group.map((r) => r.id).join(',')})`;
		const items = await az(['boards', 'query', '--org', orgUrl(org), '--project', project, '--wiql', wiql]);
		for (const item of items) {
			const f = item.fields;
			result.set(String(item.id), {
				id: String(item.id),
				label: `ADO#${item.id}`,
				url: `${orgUrl(org)}/${encodeURIComponent(project)}/_workitems/edit/${item.id}`,
				title: f['System.Title'],
				state: f['System.State'],
				type: f['System.WorkItemType'],
				assignedTo: f['System.AssignedTo']?.displayName ?? null,
				description: f['System.Description'] ?? '',
				acceptanceCriteria: f['Microsoft.VSTS.Common.AcceptanceCriteria'] ?? '',
			});
		}
	}));
	return result;
}

// States per org/project/type ("User Story" → ["New", "Active", …]), fetched once per server run.
const statesCache = new Map();
export async function states(ref, item) {
	if (!/^[\w ]+$/.test(item.type ?? '')) throw new Error('Invalid work item type');
	const key = `${ref.org}/${ref.project}/${item.type}`;
	if (!statesCache.has(key)) {
		const pending = az(['devops', 'invoke', '--area', 'wit', '--resource', 'workItemTypeStates', '--org', orgUrl(ref.org),
			'--route-parameters', `project=${ref.project}`, `type=${item.type}`, '--api-version', '7.1'])
			.then((r) => r.value.map((s) => s.name));
		statesCache.set(key, pending);
		pending.catch(() => statesCache.delete(key));
	}
	return statesCache.get(key);
}

export async function setState(ref, item, state) {
	const updated = await az(['boards', 'work-item', 'update', '--org', orgUrl(ref.org), '--id', ref.id, '--state', state]);
	return updated.fields?.['System.State'] ?? state;
}

// Newest PR from branch, preferring an open one. status: open | merged | closed.
export async function findPr(remote, branch) {
	const prs = await az(['repos', 'pr', 'list', '--org', orgUrl(remote.org), '--project', remote.project, '--repository', remote.repo,
		'--source-branch', branch, '--status', 'all']);
	const pr = prs.sort((a, b) => (a.status === 'active') - (b.status === 'active') || a.pullRequestId - b.pullRequestId).at(-1);
	if (!pr) return null;
	return {
		id: pr.pullRequestId,
		label: `PR !${pr.pullRequestId}`,
		status: { active: 'open', completed: 'merged', abandoned: 'closed' }[pr.status] ?? pr.status,
		draft: !!pr.isDraft,
		title: pr.title,
		url: `${orgUrl(remote.org)}/${encodeURIComponent(remote.project)}/_git/${encodeURIComponent(remote.repo)}/pullrequest/${pr.pullRequestId}`,
	};
}
