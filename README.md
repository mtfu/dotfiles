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

## Windows setup

1. Enable **Developer Mode** (required for Treesitter symlinks)  
   Settings → System → For developers → Developer Mode
2. Run `setup.ps1` to install programs via winget/choco and create symbolic links

## Linux / WSL setup

1. Run `install` to install programs and create symbolic links

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
