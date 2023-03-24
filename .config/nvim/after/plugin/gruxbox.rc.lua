local status, lsp = pcall(require, "lualine")
if (not status) then return end

lsp.setup {
    options = {
        theme = 'gruvbox-material'
    }
}

vim.cmd("colorscheme gruvbox-material")
