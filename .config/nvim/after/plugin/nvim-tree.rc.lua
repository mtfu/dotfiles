local status, nvimTree = pcall(require, "nvim-tree")
if (not status) then return end

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

nvimTree.setup({})

local function open_nvim_tree(_)
end

-- Only nvim
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree})

vim.keymap.set('n', '<S-M-l>', ':NvimTreeFindFileToggle<CR>')
