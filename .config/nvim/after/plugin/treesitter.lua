local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

local treesitter_install = require 'nvim-treesitter.install'

treesitter_install.prefer_git = false

local filetypes = {
    'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'rescript',
    'xml',
    'php',
    'markdown',
    'glimmer','handlebars','hbs',
    'astro'
}

treesitter.setup {
  ensure_installed = "all",
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
