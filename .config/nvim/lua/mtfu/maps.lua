vim.keymap.set('n', 'x', '"_x')

-- Delete a word backwards
vim.keymap.set('n', 'dw', 'vb"_d')


-- Map Ctrl-Backspace to delete the previous word in insert mode.
vim.keymap.set('i', '<C-BS>', '<C-W>', { noremap = true })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set('v', '<', '<gv', { noremap = true, silent = true })
vim.keymap.set('v', '>', '>gv', { noremap = true, silent = true })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- New tab
vim.keymap.set('n', 'te', ':tabedit<CR>')

-- Split window
vim.keymap.set('n', 'ss', ':split<Return><C-w>w')
vim.keymap.set('n', 'sv', ':vsplit<Return><C-w>w')


vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<CR>')

-- Gitsigns blame current line
vim.keymap.set('n', '<leader>aa', '<cmd>Gitsigns blame_line<CR>')

-- Undo Tree
vim.keymap.set('n', '<leader><F5>', '<cmd>UndotreeToggle<CR>')

-- Change path
vim.keymap.set('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>')
