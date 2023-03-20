local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

local treesitter_install = require 'nvim-treesitter.install'
treesitter_install.prefer_git = false
treesitter_install.compilers = { "gcc", "zig" }

local filetypes = {
    'html', 'javascript', 'typescript', 'tsx', 'jsx', 'markdown', 'astro'
}

treesitter.setup {
  ensure_installed = 'all',
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlightning = false,
  },
  autotag = {
    enable = true,
    filetypes = filetypes
  },
}
