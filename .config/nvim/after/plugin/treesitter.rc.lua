local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

local treesitter_install = require 'nvim-treesitter.install'
treesitter_install.prefer_git = false

local filetypes = {
    'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'rescript',
    'xml',
    'markdown',
    'astro'
}

local skip_tags = {
    'area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'slot',
    'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr', 'menuitem'
}

treesitter.setup {
    ensure_installed = { "yaml", "json", "javascript", "typescript", "lua", "c_sharp" },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlightning = false,
    },
    autotag = {
        enable = true,
        filetypes = filetypes,
        skip_tags = skip_tags
    },
}
