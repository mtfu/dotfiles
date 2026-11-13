-- Mason + LSP
require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "angularls", "powershell_es", "terraformls" },
	-- roslyn.nvim runs roslyn-language-server; lspconfig's roslyn_ls would start a second client.
	automatic_enable = { exclude = { "roslyn_ls" } },
})

require("mason-tool-installer").setup({
	-- roslyn.nvim finds roslyn-language-server in Mason's bin on its own.
	-- nvim-treesitter needs tree-sitter-cli 0.26.1+; npm's package is older.
	ensure_installed = { "prettier", "tflint", "roslyn-language-server", "tree-sitter-cli" },
	run_on_start = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf, remap = false }
		vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "grr", require("telescope.builtin").lsp_references, opts)
		vim.keymap.set("n", "grt", vim.lsp.buf.type_definition, opts)
		vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opts)
	end,
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("ts_ls", {
	settings = { completions = { completeFunctionCalls = true } },
})

-- Pass blink capabilities to all LSP servers
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- Roslyn (C#)
require("roslyn").setup({
	config = {
		settings = {
			["csharp|background_analysis"] = {
				dotnet_analyzer_diagnostics_scope = "openFiles",
			},
		},
	},
})

-- Blink.cmp (completion)
require("blink.cmp").setup({
	keymap = {
		preset = "default",
		["<CR>"] = { "accept", "fallback" },
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	}
})

-- Conform (formatting)
require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		terraform = { "terraform_fmt" },
		tf = { "terraform_fmt" },
		hcl = { "packer_fmt" },
	},
})
