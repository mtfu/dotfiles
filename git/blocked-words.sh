#!/usr/bin/env bash
# pre-commit hook, wired up in .gitconfig as hook.blockedwords. Runs only in the dotfiles repo (and its worktrees),
# which is public: refuses the commit if a staged added line contains a word from ~/.config/git/blocked-words.txt.
# That list stays on this machine, outside every repo. One word or phrase per line, matched literally and
# case-insensitively anywhere in the line (also inside longer words); blank lines and # comments are ignored.

list=~/.config/git/blocked-words.txt
here=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
# Git exports GIT_DIR to hooks, which overrides -C; without unsetting it this resolves to the current repo.
dotfiles=$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git -C ~/dotfiles rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
[ "$here" = "$dotfiles" ] || exit 0

if [ ! -f "$list" ]; then
  echo "blocked-words: $list missing, check skipped" >&2
  exit 0
fi

words=$(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$list")
[ -n "$words" ] || exit 0

# Added lines as "path:line: text".
hits=$(git diff --cached -U0 --no-color --no-ext-diff --diff-filter=ACMR |
  awk '/^\+\+\+ /{f=substr($0,7); next} /^@@/{split($3,a,/[,+]/); n=a[2]; next} /^\+/{print f ":" n ": " substr($0,2); n++}' |
  grep -i -F -- "$words")

[ -z "$hits" ] && exit 0
echo "blocked-words: staged changes contain blocked words (list: $list):" >&2
echo "$hits" >&2
exit 1
