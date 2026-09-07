# dotfiles

Personal dotfiles for Windows + WSL/Linux. Installs programs, creates symbolic links, and keeps config in sync across machines.

## What's included

- **Neovim** — Lua config with `vim.pack`, LSP via Mason, Telescope, Treesitter
- **IdeaVim** — JetBrains/Rider config mirroring Neovim keymaps
- **Zsh** — Shell config, aliases, fzf/fd/bat/starship integration
- **PowerShell** — Profile with PSfzf, PSReadLine, git/docker fuzzy helpers
- **Git** — Aliases, histogram diffs, auto-setup remote
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

## Neovim post-install

1. Open `nvim` — `vim.pack` auto-downloads missing plugins on startup
2. LSP servers auto-install on first launch via Mason (`ensure_installed`)
3. **C# only** — Roslyn requires a manual step (not supported by `ensure_installed`):
   ```
   :MasonInstall roslyn
   ```
   This uses the [Crashdummyy/mason-registry](https://github.com/Crashdummyy/mason-registry).

See [.config/nvim/NVIM_SETUP.md](.config/nvim/NVIM_SETUP.md) for full keymaps, LSP reference, and plugin commands.
