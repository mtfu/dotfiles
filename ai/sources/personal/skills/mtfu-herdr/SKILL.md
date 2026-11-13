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
| Next / previous agent (positional) | `prefix+a`, `ctrl+alt+i` / `prefix+shift+a`, `ctrl+alt+u` | `next_agent`, `previous_agent` |
| Focus agent 1–9 | `prefix+alt+1..9` | `focus_agent` |
| Back-jump to previous pane (history, crosses tabs and spaces) | `prefix+semicolon`, `ctrl+alt+p` | `last_pane` |
| Toggle / cycle panes in the current tab | `prefix+tab`, `ctrl+alt+o` / `prefix+shift+tab`, `ctrl+alt+shift+o` | `cycle_pane_next`, `cycle_pane_previous` |
| Zoom pane (default) | `prefix+z` | `zoom` |
| Jump to last notification source | `prefix+o` | `open_notification_target` |
| Next / previous tab | `prefix+n`, `ctrl+alt+m` / `prefix+p`, `ctrl+alt+n` | `next_tab`, `previous_tab` |
| Next / previous space | `ctrl+alt+j` / `ctrl+alt+k` | `next_workspace`, `previous_workspace` |
| Switch to space 1–9 | `prefix+shift+1..9` | `switch_workspace` |
| Goto picker | `prefix+g` / `ctrl+alt+g` | `goto` |
| Remove the focused space's worktree and its branch (popup, confirms) | `prefix+alt+d` | `[[keys.command]]`, `type = "popup"` (`dotfiles\herdr\remove-worktree.ps1`) |
| New worktree from the focused pane's repo (popup; native `new_worktree = ""`) | `prefix+alt+n` | `[[keys.command]]`, `type = "popup"` (`dotfiles\herdr\new-worktree.ps1`) |
| Reopen a closed space (fzf over zoxide; worktrees via `herdr worktree open`) | `prefix+shift+o` | `[[keys.command]]`, `type = "popup"` (`dotfiles\herdr\open-space.ps1`) |
| List linked worktrees of all repos, open or not; pick one to focus or open its space | `prefix+alt+l` | `[[keys.command]]`, `type = "popup"` (`dotfiles\herdr\list-worktrees.ps1`) |
| Reopen a closed worktree of the focused space's repo | `prefix+alt+o` | `open_worktree` |
| Close a space, keep files | `prefix+alt+x`, `prefix+shift+d` | `close_workspace` |
| Jump to the Main space | `ctrl+alt+slash` | `[[keys.command]]`, `type = "shell"` |
| Jump to Main's shell tab | `alt+backtick` | `[[keys.command]]`, `type = "shell"` |
| Split horizontal | `prefix+s` | `split_horizontal` |
| Settings | `prefix+comma` | `settings` |

`last_pane` follows focus history, so after visiting another space it goes there. To switch
between Copilot and nvim in the same tab, use `cycle_pane_next` (`ctrl+alt+o`), not `last_pane`.

**Main space** (the home base, replaces the old Desk and Workflow spaces): tab 1 (`shell`) is a
shell in `~` that the workspace-layout plugin also gives Copilot and nvim (intended), tab 2 (`tasks`) has Copilot for questions plus nvim on the
Obsidian task list. Other tabs (e.g. `dotfiles`) are made by hand and `main.ps1` never touches
them. Repo code goes in its own repo or worktree space. `ctrl+alt+slash` always lands on `tasks`
and `alt+backtick` on `shell`: both focus the ids cached in `%LOCALAPPDATA%\herdr-main-id`
(`<space> <tasks tab> <shell tab>`), and run `dotfiles\herdr\main.ps1 [-Tab shell]` only when the
cache is missing or stale (it recreates a closed `shell` or `tasks` tab).

Other settings: `[theme] name = "gruvbox"`, `[ui.toast] delivery = "herdr"` (in-app popups when an
agent finishes or needs input; `open_notification_target` does nothing while delivery is `off`).

### `next_agent` does NOT seek the blocked agent

**`next_agent` is purely positional:** index+1 in the sidebar's order, wrapping. `agent_panel_sort`
only changes that order, so `next_agent` can never "jump to the red one". There is no native
attention-jump action, and I deliberately removed my custom one (and its script). Do not suggest
reinstating it unless I ask.

`[ui] agent_panel_sort = "spaces"`, **not** `"priority"`: a priority-ordered panel reshuffles on
every state change and moves agents out from under `focus_agent`'s number keys. To triage by state,
use the Goto picker (`prefix+g`): `b` blocked / `w` working / `i` idle / `d` done, `a` all, `/` search.

For scripting against agent state: `herdr agent list` returns `result.agents[]` with `pane_id`,
`agent_status` (`blocked`/`working`/`idle`/`unknown`), `focused`, `state_change_seq` and
`completion_seq` (present only once an idle agent has been seen/completed).
`herdr agent focus <pane_id>` works.

Chords to avoid on my machine: `ctrl+alt+t` (Windows Terminal globalSummon), `alt+o` / `alt+y`
/ `alt+u` (AHK window focus in `dotfiles/ahk/focusprograms.ahk`). `ctrl+alt+h` and `ctrl+alt+l`
never reach herdr here (cause unknown). `prefix+shift+h/j/k/l` is
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
- Branch names: `mtfu/<type>/<work-item>-<short-desc>`, e.g. `mtfu/feat/9999-last-login`.
  `<type>` is a Conventional Commits type (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`).
  `new-worktree.ps1` adds `mtfu/` itself.
- `create` and `open` fail with `linked_worktree_source` when run from a linked worktree. Pass
  `--cwd <main checkout>` (find it with `git worktree list`, first line).
- Verify flags with `herdr worktree <cmd> --help` before using any not listed here.

### Handing the new worktree a task

My plugin `mtfu.worktree-copilot` (`dotfiles\herdr\plugins\worktree-copilot`) starts Copilot in
every new worktree. To give that agent a task, write it **before** `herdr worktree create` to
`%LOCALAPPDATA%\herdr-worktree-tasks\<slug>.md`, where `<slug>` is the branch name lowercased with
every run of characters outside `a-z0-9_-` replaced by `-` and trimmed of `-`
(`feature/123-login` → `feature-123-login`). The plugin waits until the agent is idle,
prompts "Read the task in <file> and do it.", and renames the file to `.started.md` so a reopen
doesn't repeat it. Make the task self-contained: the new agent has none of your context.

My plugin `mtfu.workspace-layout` (`dotfiles\herdr\plugins\workspace-layout`) gives every new
workspace, worktree or not, a second pane split right and zooms the first. Copilot runs in `p1`.

For an ADO story, the task file always points the new agent at the vault initiative's `START-HERE.md`,
`Tasks.md` and `Stories.md` (`obsidian-vault` skill); record the story there first if it isn't yet.

**Always write the task file, and always pass `--focus`.** The worktree is where I continue the
work, so the agent there must start with the context and I must land in it. Open questions are no
reason to skip it: the task then says which notes to read (e.g. the vault initiative's `START-HERE`,
`Tasks`, `Stories`), lists the open questions, and says to raise them with me and write no code
until they're answered. Create without a task file only when I say so.

If the agent doesn't pick up its task, `%LOCALAPPDATA%\herdr-plugins.log` says why (both plugins log every
step there). Deliver it by hand then: rename to `<slug>.started.md`, and
`herdr agent prompt <workspace>:p1 "Read the task in <full path to .started.md> and do it."`.

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

### Cursor is a fat block / nvim's insert-mode bar doesn't show

**Already fixed on my machine:** `[ui] host_cursor = "native"`. With the default `auto`, native
Windows and WSL clients get herdr's drawn cursor (avoids ConPTY flicker), which has no blink, color
or DECSCUSR shape. Values: `auto` | `native` | `drawn`; it is a client setting, so detach and
reattach if `herdr server reload-config` isn't enough. Trade-off of `native`: possible flicker
during heavy redraws.

If the shape is still stuck, check `"cursorShape"` in the WSL profile of
`dotfiles/windows-terminal/settings.json` (it pins `filledBox` as the default shape).

### A keybinding does nothing
The outer terminal or the OS ate the chord before herdr saw it. See
<https://herdr.dev/docs/keyboard/>, which lists safe chords and a prefix-free `ctrl+alt` setup.

### Agent shows the wrong state
`herdr agent list`, `herdr agent explain <target> --json`, `herdr integration status`.

### Logs
`~/.config/herdr/` (Linux/macOS/WSL) or `%APPDATA%\herdr\`; named sessions under
`sessions/<name>/`. `herdr status`, `herdr status server`, `herdr status client`.

## Rules

- When choosing or changing keybindings, read my nvim keymaps (`dotfiles\.config\nvim\lua\config\`)
  and `dotfiles\.ideavimrc` first and reuse their mnemonics (e.g. `n` new, `]`/`[` next/previous).
- **Never give tmux answers to herdr questions.** No `.tmux.conf`, no `tmux set -g`.
- Don't invent config keys, CLI flags, or keybindings. Verify against the docs pages above or
  the source before stating one.
- `HERDR_ENV=1` means the shell is already inside a herdr pane — never tell me to run `herdr`
  there, nested launches are blocked.
