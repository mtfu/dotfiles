-- Mason + LSP
require("mason").setup({
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
})

require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "angularls", "powershell_es", "terraformls" },
})

require("mason-tool-installer").setup({
	ensure_installed = { "prettier", "tflint" },
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
