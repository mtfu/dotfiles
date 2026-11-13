# Personal instructions

These are loaded into every session. Keep them short — every line is paid for on every turn.

## Size of a change

Don't bundle unrelated fixes, cleanups, or renames into work I asked for.

## Committing

Commit on your own **only** when the change is mechanical and has no logic in it:
formatting, typos, renames, generated files, lockfiles.

Anything with logic in it — new behaviour, bug fixes, refactors, config that changes what runs —
is **left unstaged, not committed**. Unstaged means unreviewed; I stage what I accept.

Never run `git push`. Ever. I push manually.

No AI attribution in commit messages — no `Co-authored-by`, no "generated with" trailers.

## Branches

Never stack a branch on unmerged work. If a story needs another branch's unmerged code, don't start it:
tell me, and park it until that branch is merged, then branch fresh from the default branch.

## Code comments

Short and concise. Never use `<c>` in XML doc comments (Rider doesn't render it); write the word plainly.

## Reviews

When I ask for a review, run the `code-review` agent and wait for it. Add `security-review` when the diff
touches auth, endpoints or request input, CLI commands built from data, security headers, pipelines or
dependencies, or agent prompts. Then check its findings against the code and against what I asked for.
"Nothing worth changing" is a fine answer. Unverifiable things (secrets, cloud config, other environments)
are one-line reminders, never findings. Never start a review on your own, not even after a change.

## Open questions

Batch them: list every open decision at once, so I can answer in one go. Only decisions; look facts
up yourself. Give each a recommended answer with a one-line reason, order by consequence, and mark
questions that depend on another. End with gaps the questions don't cover.

Where: when a vault initiative is created, write the first batch under `## Open questions` in its
`START-HERE.md` (format in the vault's `AI/AGENTS.md`), tell me in one line to open it with `<leader>ns`
in nvim, and stop. Never use
the ask_user form for a batch; it is only for a single quick question outside an initiative.

After that first batch, follow-ups (answers that raise new questions or contradict each other) are grilled in chat
with the `grill` skill, not re-batched. Otherwise use an interview/grilling skill only when I say so.
