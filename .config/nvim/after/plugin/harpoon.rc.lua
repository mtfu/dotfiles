local statusMark, mark = pcall(require, "harpoon.mark")
if (not statusMark) then return end

local statusUi, ui = pcall(require, "harpoon.ui")
if (not statusUi) then return end

vim.keymap.set("n", "<leader>ma", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<C-g>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-y>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-h>", function() ui.nav_file(4) end)
