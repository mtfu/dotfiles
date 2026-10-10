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
| ● `prefix+semicolon` | Back-jump to the previously focused pane (crosses tabs and spaces) |
| `prefix+tab` / `prefix+shift+tab` | Cycle pane next / previous |
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
| `prefix+c` | New tab |
| `prefix+shift+x` | Close tab |

## Spaces (workspaces)

| Key | Action |
|---|---|
| ● `prefix+shift+1..9` | Switch to space N |
| ● `ctrl+alt+j` / `ctrl+alt+k` | Next / previous space |
| `prefix+w` | Space picker |
| `prefix+shift+n` / `prefix+shift+d` | New / close space |

## Agents

| Key | Action |
|---|---|
| ● `prefix+alt+1..9` | Focus agent N in the sidebar |
| ● `prefix+shift+a` / `ctrl+alt+shift+a` | Next / previous agent |
| ● `prefix+g` / `ctrl+alt+g` | Goto picker — `b`/`w`/`i`/`d` to filter by state, `/` to search |
| ● `prefix+o` / `ctrl+alt+o` | Jump to whatever raised the last notification |

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

## Notes

- There is **no native attention-jump action.** `next_agent` is purely positional: it walks
  the sidebar list index+1 and wraps, so it can never seek the blocked agent.
  `agent_panel_sort` changes the order of that list, never what the key does. A custom
  `type = "shell"` command used to do attention-ranked jumping on `prefix+a`; it was dropped
  in favour of positional navigation, so `prefix+a` and `ctrl+alt+a` are free.
- `ctrl+alt+*` is unusable for some chords on Windows: the OS treats it as AltGr, and
  US-International maps AltGr+`;` to the pilcrow, so that chord never reaches herdr.
- Chords already taken on my machines: `ctrl+alt+t` (Windows Terminal globalSummon) and
  `alt+o` / `alt+y` / `alt+u` / `alt+r` (AHK window focus, see `ahk/focusprograms.ahk`).
- If a binding does nothing, the outer terminal or the OS ate it first.
  See <https://herdr.dev/docs/keyboard/> for chords that are safe.
