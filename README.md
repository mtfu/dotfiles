# dotfiles

Personal dotfiles for Windows + WSL/Linux. Installs programs, creates symbolic links, and keeps config in sync across machines.

## What's included

- **Neovim** — Lua config with `vim.pack`, LSP via Mason, Telescope, Treesitter
- **IdeaVim** — JetBrains/Rider config mirroring Neovim keymaps
- **Zsh** — Shell config, aliases, fzf/fd/bat/starship integration
- **PowerShell** — Profile with PSfzf, PSReadLine, git/docker fuzzy helpers, `killport` (kill by port, e.g. `killport 4710`, or pick listening ports in fzf)
- **Git** — Aliases, histogram diffs, auto-setup remote, worktree file copying and a secret scan (see [Git hooks](#git-hooks))
- **Windows Terminal** — Theme and profile config
- **AutoHotkey** — Windows-specific key remaps
- **Headless servers** — Minimal Neovim with OSC 52 clipboard over SSH, no plugins

## Windows setup

1. Enable **Developer Mode** (required for Treesitter symlinks)  
   Settings → System → For developers → Developer Mode
2. Run `setup.ps1` to install programs via winget/choco and create symbolic links

## Linux / WSL setup

1. Run `install.sh` to install programs and create symbolic links

## Headless server setup

For servers you only SSH into (Proxmox, Docker hosts, OMV), `install.sh` is
overkill — it installs zsh, Node, starship and a full plugin/LSP setup. Use
`install-server.sh` instead:

```bash
curl -fsSL https://raw.githubusercontent.com/mtfu/dotfiles/main/install-server.sh | bash
source ~/.bashrc
```

No clone required. It installs Neovim from the official AppImage (Debian 12
still ships 0.9.x, which is too old), writes a standalone
`~/.config/nvim/init.lua` with no plugins or LSP, and adds `v`/`vi`/`vim`
aliases plus `$EDITOR`.

The point of it is **clipboard over SSH**: yanks are sent to the local machine
via OSC 52, so copying from a remote editor lands in the Windows clipboard.

| Action              | Keys              |
| ------------------- | ----------------- |
| Copy out of Neovim  | `y` / `yy`        |
| Paste into Neovim   | `Ctrl+Shift+V`    |

Pasting *from* the system clipboard with `"+p` does not work — Windows Terminal
accepts OSC 52 writes but blocks reads. Use the terminal's own paste instead.

Re-running the script overwrites `init.lua` and upgrades Neovim to the latest
release, so it doubles as the update path.

## Post-install (all platforms)

Add to `~/.gitconfig.local`:
```ini
[user]
    email = your@email.com
    name = Your Name
```

See [Neovim post-install](#neovim-post-install) below for editor setup.

## Git hooks

Both hooks are git config-based hooks (`hook.<name>.event` / `.command`, tested on git 2.55). They run
alongside a repo's own `.git/hooks` scripts, so no `core.hooksPath` is needed. Older git ignores them.

### Copy ignored files into new worktrees (all repos)

A new worktree is a clean checkout, so ignored files such as Rider's `.idea/` and `.env` files are
missing. To bring them along, list them in a `.worktreeinclude` file at the root of the main checkout,
using `.gitignore` syntax:

```gitignore
.idea/
.env*
```

`git worktree add`, including `herdr worktree create`, then copies every file that is both ignored and
matched by `.worktreeinclude` from the main checkout. Existing files are never overwritten. Tracked
files, other ignored files (`bin/`, `obj/`) and normal checkouts are left alone.

- Commit `.worktreeinclude`, or keep it private by adding `.worktreeinclude` to `.git/info/exclude`.
- Disable it for one repo with `git config hook.worktreeinclude.enabled false`.

The hook is declared in [.gitconfig](.gitconfig), which runs [git/worktreeinclude.sh](git/worktreeinclude.sh)
through the `~/.config/git/worktreeinclude.sh` link that the setup scripts create.

### Secret scan before commit (all repos)

A `pre-commit` hook in [.gitconfig](.gitconfig) runs [gitleaks](https://github.com/gitleaks/gitleaks)
on the staged changes and refuses a commit that contains a secret. The output names the file, line and
rule. It only runs on machines using this `.gitconfig`; nothing is pushed to collaborators or CI.
Without gitleaks installed, it prints a warning and lets the commit through.

- Check by hand: `git hook run pre-commit`
- Allow a false positive: add a `gitleaks:allow` comment on the line, or list it in `.gitleaksignore`
- Skip once: `git commit --no-verify`
- Disable for one repo: `git config hook.gitleaks.enabled false`

Debian 12 and Ubuntu 22.04 have no apt package; `install.sh` warns, and you install gitleaks from its
GitHub releases.

## Neovim post-install

1. Open `nvim` — `vim.pack` auto-downloads missing plugins on startup
2. LSP servers auto-install on first launch via Mason (`ensure_installed`)
3. **C# only** — Roslyn requires a manual step (not supported by `ensure_installed`):
   ```
   :MasonInstall roslyn
   ```
   This uses the [Crashdummyy/mason-registry](https://github.com/Crashdummyy/mason-registry).

See [.config/nvim/NVIM_SETUP.md](.config/nvim/NVIM_SETUP.md) for full keymaps, LSP reference, and plugin commands.

## Herdr worktrees

`prefix+shift+d` runs [herdr/remove-worktree.ps1](herdr/remove-worktree.ps1) in a popup instead of herdr's
native `remove_worktree`. It works around two problems with the native one:

- **Herdr never deletes the branch.** The script deletes it with `git branch -d`. PRs are squash-merged, so
  `-d` usually refuses; the script then lists the unmerged commits and asks before `git branch -D`.
- **Removal fails on Windows while Copilot runs in the worktree.** Herdr runs git before the Copilot process
  tree has exited. Windows won't delete a folder that a running process is using as its working directory,
  so git fails with `Permission denied` after it has already emptied the folder and dropped its worktree
  record. Herdr then restarts the space's shells inside that folder, which keeps it locked. The script closes
  the space and deletes the empty folder. Same bug as herdr [#3314](https://github.com/herdrdev/herdr/issues/3314),
  which was marked fixed in 0.9.1 but still happens on Windows in 0.9.5.
