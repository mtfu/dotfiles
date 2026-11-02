// GitHub, through the gh CLI only (gh auth login, with the project scope for Project Status); no token in this process.
// Reads: one batched GraphQL query for issues and their Project Status, `gh pr list`. The one write: Status (or
// open/closed for an issue that is in no Project).
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export const name = 'github';

// https://github.com/<owner>/<repo>/issues/<n> → id "<owner>/<repo>#<n>"
export function parseRef(url) {
	const m = String(url).match(/^https:\/\/github\.com\/([\w.-]+)\/([\w.-]+)\/issues\/(\d+)/);
	if (!m) return null;
	return { id: `${m[1]}/${m[2]}#${m[3]}`, owner: m[1], repo: m[2], number: Number(m[3]), url: m[0] };
}

// git@github.com:owner/repo(.git) or https://github.com/owner/repo(.git)
export function parseRemote(remote) {
	const m = String(remote).trim().match(/github\.com[:/]([\w.-]+)\/([\w.-]+?)(?:\.git)?\/?$/);
	return m ? { owner: m[1], repo: m[2] } : null;
}

const safe = (s) => /^[\w.\/#:=-]+$/.test(String(s));

// Only `gh api graphql` with the queries in this file, and `gh pr list`. Never add another gh command.
let runGh = async (ghArgs) => {
	if (!(ghArgs[0] === 'api' && ghArgs[1] === 'graphql') && !(ghArgs[0] === 'pr' && ghArgs[1] === 'list')) {
		throw new Error(`gh command not allowed: ${ghArgs.slice(0, 2).join(' ')}`);
	}
	try {
		const { stdout } = await execFileAsync('gh', ghArgs, { maxBuffer: 20_000_000, windowsHide: true });
		return JSON.parse(stdout);
	} catch (err) {
		throw new Error(`gh ${ghArgs.slice(0, 2).join(' ')} failed (gh auth login?): ${String(err.stderr ?? '').trim().split('\n').at(-1) || err.message}`);
	}
};
// Tests swap in a fake gh.
export const setGhRunner = (fn) => { runGh = fn; };

async function graphql(query, variables = {}) {
	const vars = Object.entries(variables).flatMap(([k, v]) => {
		if (!safe(v)) throw new Error('Unsafe gh argument');
		return ['-f', `${k}=${v}`];
	});
	const res = await runGh(['api', 'graphql', '-f', `query=${query}`, ...vars]);
	if (res.errors?.length) throw new Error(`GitHub: ${res.errors[0].message}`);
	return res.data;
}

const ISSUE_FIELDS = `id number title url state body assignees(first: 3) { nodes { login } }
	projectItems(first: 5) { nodes { id
		project { id title field(name: "Status") { ... on ProjectV2SingleSelectField { id options { id name } } } }
		fieldValueByName(name: "Status") { ... on ProjectV2ItemFieldSingleSelectValue { name } } } }`;

const escHtml = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

// The Project item that carries Status: the first one that has a Status field.
const statusItem = (issue) => issue.projectItems?.nodes?.find((n) => n.project?.field?.options);

// refs from parseRef → Map id → item. One GraphQL query for all of them.
export async function fetchItems(refs) {
	const parts = refs.map((r, i) => {
		if (!safe(r.owner) || !safe(r.repo) || !Number.isInteger(r.number)) throw new Error(`Invalid GitHub issue ${r.id}`);
		return `i${i}: repository(owner: "${r.owner}", name: "${r.repo}") { issue(number: ${r.number}) { ${ISSUE_FIELDS} } }`;
	});
	const result = new Map();
	if (!parts.length) return result;
	const data = await graphql(`query { ${parts.join('\n')} }`);
	refs.forEach((ref, i) => {
		const issue = data[`i${i}`]?.issue;
		if (!issue) return;
		const project = statusItem(issue);
		result.set(ref.id, {
			id: ref.id,
			label: `${ref.repo}#${issue.number}`,
			url: issue.url,
			title: issue.title,
			state: project?.fieldValueByName?.name ?? (issue.state === 'OPEN' ? 'Open' : 'Closed'),
			type: project ? `Project: ${project.project.title}` : 'Issue',
			assignedTo: issue.assignees.nodes.map((a) => a.login).join(', ') || null,
			description: issue.body ? `<pre>${escHtml(issue.body)}</pre>` : '',
			acceptanceCriteria: '',
			// Kept server-side for states/setState; stripped before sending to the page.
			_github: { issueId: issue.id, project: project && { itemId: project.id, projectId: project.project.id, fieldId: project.project.field.id, options: project.project.field.options } },
		});
	});
	return result;
}

export async function states(ref, item) {
	const project = item._github?.project;
	return project ? project.options.map((o) => o.name) : ['Open', 'Closed'];
}

export async function setState(ref, item, state) {
	const gh = item._github;
	if (gh?.project) {
		const option = gh.project.options.find((o) => o.name === state);
		if (!option) throw new Error(`No Status "${state}"`);
		await graphql(
			'mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) { updateProjectV2ItemFieldValue(input: { projectId: $p, itemId: $i, fieldId: $f, value: { singleSelectOptionId: $o } }) { projectV2Item { id } } }',
			{ p: gh.project.projectId, i: gh.project.itemId, f: gh.project.fieldId, o: option.id },
		);
		return state;
	}
	const mutation = state === 'Closed'
		? 'mutation($id: ID!) { closeIssue(input: { issueId: $id }) { issue { state } } }'
		: 'mutation($id: ID!) { reopenIssue(input: { issueId: $id }) { issue { state } } }';
	await graphql(mutation, { id: gh.issueId });
	return state;
}

// Newest PR from branch, preferring an open one. status: open | merged | closed.
export async function findPr(remote, branch) {
	if (!safe(remote.owner) || !safe(remote.repo) || !safe(branch)) throw new Error('Unsafe gh argument');
	const prs = await runGh(['pr', 'list', '--repo', `${remote.owner}/${remote.repo}`, '--head', branch, '--state', 'all',
		'--json', 'number,state,isDraft,title,url']);
	const pr = prs.sort((a, b) => (a.state === 'OPEN') - (b.state === 'OPEN') || a.number - b.number).at(-1);
	if (!pr) return null;
	return {
		id: pr.number,
		label: `PR #${pr.number}`,
		status: { OPEN: 'open', MERGED: 'merged', CLOSED: 'closed' }[pr.state] ?? pr.state.toLowerCase(),
		draft: !!pr.isDraft,
		title: pr.title,
		url: pr.url,
	};
}
