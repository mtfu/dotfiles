#!/usr/bin/env bash
#
# Minimal nvim setup for headless servers (Proxmox, Docker host, OMV).
# Standalone: no plugins, no LSP, no zsh, no snap. Just an editor with a
# working clipboard over SSH via OSC 52.
#
# Neovim is installed from the official AppImage rather than apt, because
# OSC 52 needs >= 0.10 and Debian 12 still ships 0.9.x. This also keeps
# every server on the same version.
#
# Usage:  ./install-server.sh
#     or: curl -fsSL https://raw.githubusercontent.com/mtfu/dotfiles/main/install-server.sh | bash

set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

echo "==> Installing dependencies"
$SUDO apt-get update -qq
$SUDO apt-get install -y curl ca-certificates

echo "==> Installing neovim (AppImage)"
arch="$(uname -m)"
case "$arch" in
  x86_64)  asset="nvim-linux-x86_64.appimage"  ;;
  aarch64) asset="nvim-linux-arm64.appimage"   ;;
  *) echo "!!  Unsupported architecture: $arch" >&2; exit 1 ;;
esac

curl -fsSL -o /tmp/nvim.appimage \
  "https://github.com/neovim/neovim/releases/latest/download/${asset}"
chmod +x /tmp/nvim.appimage

# Remove any apt-installed neovim so there is only one on PATH.
$SUDO apt-get remove -y neovim >/dev/null 2>&1 || true

if /tmp/nvim.appimage --version >/dev/null 2>&1; then
  $SUDO mv /tmp/nvim.appimage /usr/local/bin/nvim
else
  # No FUSE (common on minimal images) -- extract and link the binary instead.
  echo "==> AppImage won't run directly (no FUSE); extracting"
  $SUDO rm -rf /opt/nvim
  $SUDO mkdir -p /opt/nvim
  ( cd /opt/nvim && $SUDO /tmp/nvim.appimage --appimage-extract >/dev/null )
  $SUDO ln -sf /opt/nvim/squashfs-root/usr/bin/nvim /usr/local/bin/nvim
  rm -f /tmp/nvim.appimage
fi

hash -r
echo "==> $(nvim --version | head -1)"

echo "==> Writing ~/.config/nvim/init.lua"
mkdir -p "${HOME}/.config/nvim"
cat > "${HOME}/.config/nvim/init.lua" << 'EOF'
-- Minimal server config. Managed by install-server.sh -- edits get overwritten.

vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.backup = false

-- Plain `y` goes to the system clipboard, matching the desktop config.
vim.opt.clipboard = 'unnamedplus'

-- Over SSH there is no local clipboard, so route copies through OSC 52.
-- Paste reads the unnamed register instead of querying the terminal:
-- Windows Terminal accepts OSC 52 writes but never answers reads, which
-- would otherwise hang nvim for ~10s on every yank and paste.
-- To paste *from* Windows, use Ctrl+Shift+V in the terminal.
if vim.env.SSH_TTY then
  local function paste()
    return {
      vim.split(vim.fn.getreg('"'), '\n'),
      vim.fn.getregtype('"'),
    }
  end

  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end
EOF

echo "==> Adding aliases to ~/.bashrc"
if ! grep -q "dotfiles: server nvim" "${HOME}/.bashrc" 2>/dev/null; then
  cat >> "${HOME}/.bashrc" << 'EOF'

# --- dotfiles: server nvim ---
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
export EDITOR=nvim
export VISUAL=nvim
EOF
fi

cat << 'EOF'

Done. Run 'source ~/.bashrc', then test:
  v /tmp/test.txt  ->  yank a line with yy  ->  Ctrl+V into any Windows app

Copy out of nvim:  y / yy / "+y   (via OSC 52)
Paste into nvim:   Ctrl+Shift+V   (terminal paste; OSC 52 reads are blocked)
EOF
