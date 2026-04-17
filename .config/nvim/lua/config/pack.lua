vim.pack.add({
	-- Shared dependencies (must come first)
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",

	-- Editing utilities
	"https://github.com/tpope/vim-surround",
	"https://github.com/tpope/vim-commentary",
	"https://github.com/tpope/vim-repeat",
	"https://github.com/vim-scripts/ReplaceWithRegister",
	"https://github.com/nanotee/zoxide.vim",
	"https://github.com/ovk/endec.nvim",

	-- Colorscheme + statusline
	"https://github.com/sainnhe/gruvbox-material",
	"https://github.com/nvim-lualine/lualine.nvim",

	-- Fuzzy finder + lazygit
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/kdheepak/lazygit.nvim",

	-- Pairs & tags
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/windwp/nvim-ts-autotag",

	-- Git
	"https://github.com/lewis6991/gitsigns.nvim",

	-- File tree + filesystem editing
	"https://github.com/nvim-tree/nvim-tree.lua",
	"https://github.com/stevearc/oil.nvim",

	-- Treesitter
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",

	-- Text objects
	"https://github.com/tommcdo/vim-exchange",

	-- LSP
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
	"https://github.com/neovim/nvim-lspconfig",

	-- Csharp, remember to use :MasonInstall Roslyn
	"https://github.com/seblyng/roslyn.nvim",

	-- Completion
	{ src = "https://github.com/saghen/blink.cmp", version = "v1" },

	-- Formatting
	"https://github.com/stevearc/conform.nvim",

	-- Terminal
	"https://github.com/akinsho/toggleterm.nvim",
})
