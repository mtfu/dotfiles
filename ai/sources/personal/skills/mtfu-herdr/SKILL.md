---
name: mtfu-herdr
description: >
  What Herdr is and how it is configured on my machines. USE FOR: any mention of "herdr"
  (however it is spelled or typo'd) — pane/tab/workspace layout, the sidebar, agent state,
  keybindings, the config file, the `herdr` CLI or socket API, and anything that behaves
  differently "in herdr" than in a bare terminal (cursor shape, keys being swallowed, colors,
  scrollback, clipboard). Never guess what herdr is, and never answer a herdr question with
  tmux or zellij advice. ALSO USE FOR: creating, opening, listing or removing a git worktree
  when HERDR_ENV=1 — use `herdr worktree`, never plain `git worktree add`.
  DO NOT USE FOR: tmux, zellij, screen, Windows Terminal, or
  Ghostty/WezTerm questions that do not involve herdr.
---

# Herdr

**Herdr is a terminal multiplexer.** Not a terminal emulator, not an editor, not a shell.
When I say "herdr" I mean this tool — do not ask me what it is again.

- Site / docs: <https://herdr.dev/docs/>
- Agent-facing overview (fetch this before answering anything non-trivial):
  <https://herdr.dev/agent-guide.md>
- Source: <https://github.com/herdrdev/herdr> (Rust, AGPL-3.0)
- Skill for *driving* herdr from inside a pane:
  <https://raw.githubusercontent.com/herdrdev/herdr/master/skills/herdr/SKILL.md>

It is tmux-shaped — a background server owns the PTYs, clients attach and render, panes
survive detach and SSH drops — but it is mouse-first and **agent-aware**: it detects coding
agents running in panes and shows `working` / `blocked` / `done` / `idle` / `unknown` per pane
in a sidebar. Terminal emulation is the embedded **Ghostty** VT engine (`libghostty-vt`).

Concept model: **session → workspace → tab → pane → agent**. Default prefix is `ctrl+b`;
`prefix+?` lists live bindings. Detach `prefix+q`. Stop everything: `herdr server stop`.

## Config

| Platform | Path |
|---|---|
| Linux / macOS / **WSL** | `~/.config/herdr/config.toml` |
| Native Windows | `%APPDATA%\herdr\config.toml` |

TOML, optional — herdr runs fine with no config. Sections: `[keys]`, `[theme]`, `[ui]`,
`[terminal]`, `[update]`, `[experimental]`.

- `herdr --default-config` prints the full default file.
- `herdr server reload-config` applies edits live (or global menu → *reload config*).
- Invalid values fall back to a safe default with a startup warning.
- Full reference: <https://herdr.dev/docs/config-reference/>

**My setup runs herdr natively on Windows** (`C:\tools\herdr\herdr.exe`), so my config is
`%APPDATA%\herdr\config.toml` — *not* a WSL-side one, even though I use WSL for other things.

## My keybindings

Set in `%APPDATA%\herdr\config.toml`. Defaults stay active unless listed here.

| Action | Key | Config key |
|---|---|---|
| Cycle agents positionally | `prefix+shift+a`, `ctrl+alt+shift+a` | `next_agent`, `previous_agent` |
| Focus agent 1–9 | `prefix+alt+1..9` | `focus_agent` |
| Back-jump to previous pane | `prefix+semicolon` | `last_pane` |
| Jump to last notification source | `prefix+o` / `ctrl+alt+o` | `open_notification_target` |
| Next / previous space | `ctrl+alt+j` / `ctrl+alt+k` | `next_workspace`, `previous_workspace` |
| Switch to space 1–9 | `prefix+shift+1..9` | `switch_workspace` |
| Goto picker | `prefix+g` / `ctrl+alt+g` | `goto` |
| Split horizontal | `prefix+s` | `split_horizontal` |
| Settings | `prefix+comma` | `settings` |

### `next_agent` does NOT seek the blocked agent

Important and non-obvious: **`next_agent` is purely positional.** It takes the agent list in
whatever order the sidebar uses and moves index+1, wrapping. `agent_panel_sort` only changes the
*order of the list*, never what the key does — so `next_agent` can never "jump to the red one".

herdr's own attention ranking (`pane_attention_priority`, `src/workspace/aggregate.rs`) is:

```
blocked (4) > idle-unseen (3) > working (2) > idle-seen (1) > unknown (0)
```

Note **idle-unseen outranks working**, which is why priority-ordered cycling feels wrong when
triaging by hand — finished-but-unlooked-at agents come before the ones actively running.

**There is no native attention-jump action, and I have deliberately stopped trying to build one.**
A custom `type = "shell"` command doing this used to be bound to `prefix+a`; it was removed, along
with its script, in favour of plain positional navigation. Do not suggest reinstating it unless I
ask. `prefix+a` and `ctrl+alt+a` are now free.

`[ui] agent_panel_sort = "spaces"` — grouped by space, **not** `"priority"`. Navigation here is
positional, and a priority-ordered panel reshuffles on every state change, which moves agents out
from under `focus_agent`'s number keys. Stable order is the whole point. When I do want to triage
by state, that is what the Goto picker is for.

For scripting against agent state anyway: `herdr agent list` returns `result.agents[]` with
`pane_id`, `agent_status` (`blocked`/`working`/`idle`/`unknown`), `focused`, `state_change_seq`,
and `completion_seq` (present only once an idle agent has been seen/completed).
`herdr agent focus <pane_id>` works.

The Goto picker (`prefix+g`) filters with `b` blocked / `w` working / `i` idle / `d` done,
`a` for all, `/` to search.

Chords to avoid on my machine: `ctrl+alt+t` (Windows Terminal globalSummon), `alt+o` / `alt+y`
/ `alt+u` (AHK window focus in `dotfiles/ahk/focusprograms.ahk`). `prefix+shift+h/j/k/l` is
swap-pane and has no config key, so don't shadow it.

## Plugins

Local executables with a `herdr-plugin.toml` manifest; `herdr plugin install owner/repo`.
Marketplace at <https://herdr.dev/plugins/> indexes the GitHub topic `herdr-plugin`, unreviewed.
Plugin v1 has **no runtime action registration and no native non-terminal UI** — actions, event
hooks, panes and link handlers are all declared in the manifest. So a plugin can never add
navigation UI; navigation is core-only.

Worth knowing about:
- `ogulcancelik/herdr-plugin-examples` — reference examples only (telegram notify, github link
  preview, dev layout bootstrap).

## Worktrees — always use `herdr worktree`

When `HERDR_ENV=1`, create and open git worktrees through herdr, **not** `git worktree add`.
herdr then opens the checkout as its own workspace (sidebar, agent state per worktree).

```
herdr worktree list                                   # JSON; open_workspace_id shows which are open
herdr worktree create --branch <name> [--base <ref>] [--path <dir>] [--label <text>] [--focus]
herdr worktree open   --path <dir> | --branch <name>  # existing checkout -> herdr workspace
herdr worktree remove ...
```

- A worktree made with plain `git worktree add` is not lost: `herdr worktree open --path <dir>`
  adopts it as a workspace without touching git or files.
- My worktrees live next to the repo as `C:\repos\wt-<short-name>`.
- Verify flags with `herdr worktree <cmd> --help` before using any not listed here.

### Handing the new worktree a task

My plugin `mtfu.worktree-copilot` (`dotfiles\herdr\plugins\worktree-copilot`) starts Copilot in
every new worktree. To give that agent a task, write it **before** `herdr worktree create` to
`%LOCALAPPDATA%\herdr-worktree-tasks\<slug>.md`, where `<slug>` is the branch name lowercased with
every run of characters outside `a-z0-9_-` replaced by `-` and trimmed of `-`
(`feature/123-login` → `feature-123-login`). The plugin waits until the agent is idle,
prompts "Read the task in <file> and do it.", and renames the file to `.started.md` so a reopen
doesn't repeat it. Make the task self-contained: the new agent has none of your context.

Without a task file the agent just starts idle. For an already running agent, use
`herdr agent prompt <pane-or-name> "<text>"`.

## Popups are native, no plugin needed

```toml
[[keys.command]]
key = "prefix+alt+g"
type = "popup"
command = "lazygit"
width = "80%"
height = "80%"
```

`type` is `popup` (session-modal, no layout change, grabs all input incl. Escape), `pane`
(temporary zoomed pane), `shell` (detached, no UI), or `plugin_action`. On Windows the command
string runs through `cmd.exe /d /c`. Popups expose `HERDR_ACTIVE_PANE_ID`, not `HERDR_PANE_ID`.

## Known gotchas

### Cursor is always a fat block on Windows/WSL (nvim insert mode looks wrong)

This is deliberate, not a bug. Windows terminals drive herdr through ConPTY, where the native
host cursor flickers and jumps during full-screen redraws. So `[ui] host_cursor = "auto"` —
the default — makes **native Windows and WSL clients draw herdr's own cursor as cell content**,
while Linux and macOS clients keep the host cursor. A drawn cursor is a steady block: it has no
blink, no host cursor color, and **no DECSCUSR shape**, so nvim's `guicursor` bar-in-insert
never shows up.

Fix — opt back into the outer terminal's cursor:

```toml
[ui]
host_cursor = "native"
```

Then `herdr server reload-config`. Values: `auto` (default, platform-decided) | `native`
(always host cursor) | `drawn` (always herdr-drawn). `host_cursor` is a *client* setting, so
detach and reattach if a reload alone doesn't take effect.

**Already applied on my machine** — `[ui] host_cursor = "native"` is set in
`%APPDATA%\herdr\config.toml`.

Herdr *does* forward DECSCUSR (`CSI <n> SP q`) to attached clients — see `src/pane/cursor.rs`
and `decscusr_cursor_shape` in `src/pane/terminal.rs` — but only when the host cursor is in
use. Trade-off of `native` on Windows/WSL: possible cursor flicker or stale positions during
heavy redraws.

With `host_cursor = "native"`, the outer terminal's own shape setting matters again. In my
`dotfiles/windows-terminal/settings.json` the WSL profile pins `"cursorShape": "filledBox"`,
which is only the *default* shape — Windows Terminal still honors app DECSCUSR — but if the
cursor is still stuck, that line is the next thing to check.

### A keybinding does nothing
The outer terminal or the OS ate the chord before herdr saw it. See
<https://herdr.dev/docs/keyboard/>, which lists safe chords and a prefix-free `ctrl+alt` setup.

### Agent shows the wrong state
`herdr agent list`, `herdr agent explain <target> --json`, `herdr integration status`.

### Logs
`~/.config/herdr/` (Linux/macOS/WSL) or `%APPDATA%\herdr\`; named sessions under
`sessions/<name>/`. `herdr status`, `herdr status server`, `herdr status client`.

## Rules

- **Never give tmux answers to herdr questions.** No `.tmux.conf`, no `tmux set -g`.
- Don't invent config keys, CLI flags, or keybindings. Verify against the docs pages above or
  the source before stating one.
- `HERDR_ENV=1` means the shell is already inside a herdr pane — never tell me to run `herdr`
  there, nested launches are blocked.
