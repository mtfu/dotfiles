# Herdr keybindings

Quick reference for my [herdr](https://herdr.dev/docs/) setup.

Prefix is `ctrl+b` — press and release, then the action key. `prefix+?` lists the live
bindings straight from the running server, which always beats this file.

**●** marks a personal override in `config.toml`. Everything unmarked is a herdr default.

> Source of truth is [`config.toml`](config.toml), symlinked to `%APPDATA%\herdr\config.toml`
> by `updateSymbolicLinks.ps1`. If you change a binding there, change it here too.

## Panes

| Key | Action |
|---|---|
| `prefix+h` / `j` / `k` / `l` | Focus pane left / down / up / right |
| ● `prefix+semicolon` / `ctrl+alt+p` | Back-jump to the previously focused pane (crosses tabs and spaces) |
| ● `prefix+tab` / `ctrl+alt+o` | Cycle pane next (toggles when the tab has two panes) |
| ● `prefix+shift+tab` / `ctrl+alt+shift+o` | Cycle pane previous |
| `prefix+v` | Split right |
| ● `prefix+s` | Split down |
| `prefix+z` | Zoom pane fullscreen (toggle) |
| `prefix+r` | Resize mode |
| `prefix+x` | Close pane |
| `prefix+shift+h/j/k/l` | **Swap** pane position — moves the pane, not the focus |

## Tabs

| Key | Action |
|---|---|
| `prefix+1..9` | Switch to tab N |
| ● `ctrl+alt+m` / `ctrl+alt+n` | Next / previous tab (`prefix+n` / `prefix+p` still work) |
| `prefix+c` | New tab |
| `prefix+shift+x` | Close tab |

## Spaces (workspaces)

| Key | Action |
|---|---|
| ● `prefix+shift+1..9` | Switch to space N |
| ● `ctrl+alt+j` / `ctrl+alt+k` | Next / previous space |
| ● `ctrl+alt+/` | Go to the "Main" space, always on its `tasks` tab: Copilot (`$OBSIDIAN_VAULT`, else Desktop) + nvim on Obsidian `01 - Next Actions.md`; creates what is missing (`main.ps1`) |
| ● `` alt+` `` | Go to Main's `shell` tab (tab 1): a shell in `~` (with Copilot and nvim from workspace-layout), for jumping around with `z` (`main.ps1 -Tab shell`) |
| `prefix+w` | Space picker |
| ● `prefix+alt+x` / `prefix+shift+d` | Close the space, keep the files (`close_workspace`) |
| ● `prefix+alt+d` | Remove the space's worktree, then its branch (popup, `remove-worktree.ps1`; asks before discarding changes or force-deleting an unmerged branch) |
| ● `prefix+alt+n` | New worktree space from the repo of the folder you are in, also after `z <repo>` in Main's shell (popup asks branch and adds `mtfu/` if missing, base defaults to origin's default branch; `new-worktree.ps1`, replaces native `new_worktree`) |
| ● `prefix+alt+p` | Review a PR: paste an ADO or GitHub PR URL; checks out its branch as `C:\repos\wt-review-<id>` and starts Copilot there with a task to run the code and security reviews (popup, `review-pr.ps1`; focuses the space if it already exists) |
| ● `prefix+shift+o` | Reopen a closed space: fzf over zoxide folders; worktrees reopen as worktree spaces, an open one is focused (popup, `open-space.ps1`) |
| ● `prefix+alt+o` | Reopen a closed (not deleted) worktree of the focused space's repo (native `open_worktree`) |
| ● `prefix+alt+l` | List the linked worktrees of all repos (`C:\repos`, dotfiles), open or not; type a pick number to focus its space or open it as one (popup, `list-worktrees.ps1`) |
| `prefix+shift+n` | New space |

## Agents

| Key | Action |
|---|---|
| ● `prefix+alt+1..9` | Focus agent N in the sidebar |
| ● `prefix+a` / `ctrl+alt+i` | Next agent |
| ● `prefix+shift+a` / `ctrl+alt+u` | Previous agent |
| ● `prefix+g` / `ctrl+alt+g` | Goto picker — `b`/`w`/`i`/`d` to filter by state, `/` to search |
| `prefix+o` | Jump to the agent behind the visible popup (only while it is on screen) |

## Session

| Key | Action |
|---|---|
| `prefix+b` | Toggle sidebar |
| `prefix+q` | Detach — panes keep running |
| `prefix+?` | Help / live bindings |
| ● `prefix+comma` | Settings |

## How to navigate

**The number row is the backbone.** One gesture, modifier picks the level:

```
prefix+1..9        tabs
prefix+shift+1..9  spaces
prefix+alt+1..9    agents
```

No cycling and no counting. This only works while positions stay put, which is why
`[ui] agent_panel_sort` is `"spaces"` and not `"priority"` — a priority-ordered panel
reshuffles on every state change and moves agents out from under the number keys.

**`prefix+semicolon` is the highest-value key.** Real work is ping-pong between two
places, editor and agent or agent and logs, and back-jump is the only motion that works
at every level. Build this reflex first.

**`prefix+h/j/k/l` inside a tab.** Absolute rather than historical: `prefix+l` always goes
right. Prefer it to `prefix+tab` whenever a tab holds more than two panes, because cycle
order is layout order and that is rarely what you mean.

**`prefix+g` is the escape hatch** — for when you don't know where something is, or want to
triage by state. `prefix+g` then `b` walks the blocked agents. Don't use it for places you
visit often; that is what the number row is for.

Rough hierarchy: back-jump if you were just there → number row if you know where it is →
picker if you don't.

## Main flow (tasks while coding)

Main is the home base. Tab 1 (`shell`) is a shell in `~`, laid out with Copilot and nvim by workspace-layout: quick one-offs, `z` into a
repo, `prefix+alt+n` from there for a worktree space. Tab 2 (`tasks`) shows the Obsidian task
list (`01 - Next Actions.md`) next to Copilot. Add other tabs (e.g. `dotfiles`) by hand when needed;
`main.ps1` leaves them alone. Repo code goes in its own repo or worktree space.

1. `ctrl+alt+/` — jump to Main's `tasks` tab from anywhere (recreates it if it was closed).
2. `prefix+z` on the nvim pane — zoom it, so Main opens straight on the task list. The zoom
   sticks between visits.
3. `ctrl+alt+o` — toggle to Copilot (still works while zoomed) for a question, and back.
4. `` alt+` `` — jump to Main's `shell` tab.
5. `ctrl+alt+p` — back to the code you came from.

nvim reloads the note on focus (`autoread` + `checktime`), so tasks added from Obsidian or by
Copilot show up when you arrive. Unsaved edits in nvim are never overwritten silently.

## Notes

- There is **no native attention-jump action.** `next_agent` is purely positional: it walks
  the sidebar list index+1 and wraps, so it can never seek the blocked agent.
  `agent_panel_sort` changes the order of that list, never what the key does. A custom
  `type = "shell"` command used to do attention-ranked jumping on `prefix+a`; it was dropped
  in favour of positional navigation, so `prefix+a` and `ctrl+alt+a` are free.
- Windows treats ctrl+left alt as AltGr, so on US-International `ctrl+alt+;` used to arrive
  as `¶`. Windows Terminal has `"altGrAliasing": false` to stop that; real AltGr (right alt)
  still types ø etc.
- Even so, `ctrl+alt+h`, `ctrl+alt+l` and `ctrl+alt+0` never reach herdr (cause unknown).
  Verified working: `j k g y u i o [ ]`.
- herdr has no "last tab" action; `ctrl+alt+p` (last pane) is the closest.
- Direct chords are laid out as pairs on the right hand: `y/u` tabs, `i/o` agents,
  `j/k` spaces, `p` back-jump.
- Chords already taken on my machines: `ctrl+alt+t` (Windows Terminal globalSummon) and
  `alt+o` / `alt+y` / `alt+u` / `alt+r` (AHK window focus, see `ahk/focusprograms.ahk`).
- If a binding does nothing, the outer terminal or the OS ate it first.
  See <https://herdr.dev/docs/keyboard/> for chords that are safe.
