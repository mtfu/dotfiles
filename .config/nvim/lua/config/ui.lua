-- Colorscheme + statusline
require("lualine").setup({ options = { theme = "gruvbox-material" } })
vim.cmd("colorscheme gruvbox-material")

-- Nvim-tree
require("nvim-tree").setup({
	hijack_directories = { enable = true, auto_open = false },
	view = { width = { min = 30, max = 80 } },
})
vim.keymap.set("n", "<S-M-l>", ":NvimTreeFindFile<CR>")

-- Oil (filesystem editing)
require("oil").setup({ view_options = { show_hidden = true } })
vim.keymap.set("n", "-", "<CMD>Oil<CR>")

-- Toggleterm
require("toggleterm").setup({
	size = 20,
	open_mapping = [[<C-\>]],
	hide_numbers = true,
	shade_terminals = true,
	shading_factor = 1,
	start_in_insert = true,
	insert_mappings = true,
	persist_size = true,
	direction = "float",
	close_on_exit = true,
	shell = vim.fn.has("win32") == 1 and "pwsh.exe" or vim.o.shell,
})
