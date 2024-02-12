local harpoonStatus, harpoon  = pcall(require, "harpoon")
if (not harpoonStatus) then return end

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set("n", "<leader>ma", function() harpoon:list():append() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-h><C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-h><C-j>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-h><C-k>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-h><C-l>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<C-h><C-p>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-h><C-n>", function() harpoon:list():next() end)
