#!/usr/bin/env bash
# post-checkout hook, wired up in .gitconfig as hook.worktreeinclude.
# On a new worktree, copies the ignored files listed in the main checkout's .worktreeinclude
# (e.g. .idea/, .env*) into it. Same file format as Claude Code and Worktrunk.

# $1 (previous HEAD) is all zeros only for a fresh checkout: git worktree add or clone.
case $1 in *[!0]* | '') exit 0 ;; esac

wt=$(git rev-parse --show-toplevel) || exit 0
main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)") || exit 0
# A clone is its own main checkout; only linked worktrees need copying.
[ "$wt" != "$main" ] && [ -f "$main/.worktreeinclude" ] || exit 0

git -C "$main" ls-files -z --others --ignored --exclude-from="$main/.worktreeinclude" |
  while IFS= read -r -d '' rel; do
    [ -e "$wt/$rel" ] && continue          # never overwrite
    mkdir -p "$(dirname "$wt/$rel")" && cp -p "$main/$rel" "$wt/$rel" && echo "worktreeinclude: copied $rel"
  done

# The hook's exit status becomes git checkout's, so a failed copy must not fail the checkout.
exit 0
