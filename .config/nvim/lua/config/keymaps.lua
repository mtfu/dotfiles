-- ReplaceWithRegister
vim.keymap.set("n", "cp", "<Plug>ReplaceWithRegisterOperator", { silent = true })
vim.keymap.set("x", "cp", "<Plug>ReplaceWithRegisterVisual", { silent = true })
vim.keymap.set("n", "cpp", "<Plug>ReplaceWithRegisterLine", { silent = true })

vim.keymap.set("i", "<C-H>", "<C-W>", { noremap = true })

vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "]e", function()
	vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
end)
vim.keymap.set("n", "[e", function()
	vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
end)

vim.keymap.set("n", "gl", vim.diagnostic.open_float)
for _, lhs in ipairs({ "<A-0>", "<leader>q" }) do
	vim.keymap.set("n", lhs, function()
		vim.diagnostic.setqflist()
	end)
end

vim.keymap.set("n", "<A-\\>", require("telescope.builtin").lsp_document_symbols)
vim.keymap.set("n", "<leader>lg", "<cmd>LazyGit<CR>")
vim.keymap.set("n", "<leader>aa", "<cmd>Gitsigns blame_line<CR>")
vim.keymap.set("n", "<leader>cd", ":cd %:p:h<CR>:pwd<CR>")
vim.keymap.set("n", "<leader>yp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify(path)
end)
 -- fuzzy; q: for full editable history; @: to repeat last command
vim.keymap.set("n", "<leader>:", "<cmd>Telescope command_history<CR>")

-- Format via conform, fallback to LSP
vim.keymap.set({ "n", "v" }, "<leader><leader>", function()
	require("conform").format({ async = true, lsp_fallback = true })
end)
