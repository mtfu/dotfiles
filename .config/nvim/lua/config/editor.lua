-- Telescope
local telescope = require("telescope")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")

telescope.setup({
	defaults = {
		mappings = {
			i = {
				["<C-j>"] = actions.move_selection_next,
				["<C-k>"] = actions.move_selection_previous,
			},
			n = {
				["<C-j>"] = actions.move_selection_next,
				["<C-k>"] = actions.move_selection_previous,
			},
		},
		file_ignore_patterns = { "node_modules", "yarn.lock" },
	},
	pickers = {
		live_grep = {
			additional_args = function(_)
				return { "--hidden" }
			end,
		},
		find_files = {
			find_command = { "fd", "--type", "f", "--color=never", "--hidden", "--follow", "-E", ".git/*" },
		},
	},
})
telescope.load_extension("lazygit")

vim.keymap.set("n", "<c-p>", builtin.find_files, {})
vim.keymap.set("n", "<leader>hh", builtin.oldfiles, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>ff", builtin.grep_string, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>fs", builtin.lsp_dynamic_workspace_symbols, {})
vim.keymap.set("n", "<leader>fc", function()
	builtin.lsp_dynamic_workspace_symbols({ symbols = "class" })
end, {})

-- Treesitter
require("nvim-treesitter").setup({
	ensure_installed = { "yaml", "json", "javascript", "typescript", "tsx", "html", "lua", "c_sharp", "terraform", "hcl" },
	auto_install = true,
})

-- Treesitter textobjects
require("nvim-treesitter-textobjects").setup({
	select = {
		enable = true,
		lookahead = true,
		keymaps = {
			["af"] = "@function.outer",
			["if"] = "@function.inner",
			["aa"] = "@parameter.outer",
			["ia"] = "@parameter.inner",
		},
	},
	move = {
		enable = true,
		goto_next_start     = { ["]]"] = "@function.outer" },
		goto_previous_start = { ["[["] = "@function.outer" },
	},
})

-- Pairs & autotag
require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()

-- Gitsigns
require("gitsigns").setup()
