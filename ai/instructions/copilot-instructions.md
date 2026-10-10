# Personal instructions

These are loaded into every session. Keep them short — every line is paid for on every turn.

## Size of a change

One logical change per turn. If a request contains several, do the first and say what is left.
Don't bundle unrelated fixes, cleanups, or renames into work I asked for.

## Committing

Commit on your own **only** when the change is mechanical and has no logic in it:
formatting, typos, renames, generated files, lockfiles.

Anything with logic in it — new behaviour, bug fixes, refactors, config that changes what runs —
gets **staged, not committed**. I review the index myself; unstaged means unreviewed.

Never run `git push`. Ever. I push manually.

No AI attribution in commit messages — no `Co-authored-by`, no "generated with" trailers.
