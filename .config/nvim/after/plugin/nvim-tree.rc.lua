local status, nvimTree = pcall(require, "nvim-tree")
if (not status) then return end

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

nvimTree.setup({
    hijack_directories = {
        enable = true,
        auto_open = false,
    },
    view = {
        width = {
            min = 30,
            max = 80
        }
    }
})

vim.keymap.set('n', '<S-M-l>', ':NvimTreeFindFile<CR>')
