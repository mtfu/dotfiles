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

## Code comments

Short and concise. Never use `<c>` in XML doc comments (Rider doesn't render it); write the word plainly.

## Reviews

When I ask for a review, load `mtfu-review-clean-verdict` first and review it yourself, following it.
Never start any other review skill on your own, not even after a change; only when I name it.

## Open questions

Batch them: list every open decision at once, so I can answer in one go. Only decisions; look facts
up yourself. Give each a recommended answer with a one-line reason, order by consequence, and mark
questions that depend on another. End with gaps the questions don't cover.

If my answers invalidate other questions or contradict each other, list those and ask whether to
grill them or re-batch. Use an interview/grilling skill only when I say so.
