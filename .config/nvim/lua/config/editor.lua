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
				return { "--hidden", "--glob", "!**/.git/*" }
			end,
		},
		grep_string = {
			additional_args = function(_)
				return { "--hidden", "--glob", "!**/.git/*" }
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
vim.keymap.set("n", "<leader>fr", builtin.registers, {})
vim.keymap.set("n", "<leader>fs", builtin.lsp_dynamic_workspace_symbols, {})
vim.keymap.set("n", "<leader>fc", function()
	builtin.lsp_dynamic_workspace_symbols({ symbols = "class" })
end, {})

-- Treesitter
require("nvim-treesitter").setup({
	ensure_installed = { "yaml", "json", "javascript", "typescript", "tsx", "html", "lua", "c_sharp", "terraform", "hcl", "markdown", "markdown_inline" },
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

-- Markdown: render headings, lists, tables and code blocks in the buffer itself.
-- Rendered in normal mode, raw source in insert mode, so editing is never obscured.
require("render-markdown").setup({
	completions = { lsp = { enabled = true } },
})

vim.keymap.set("n", "<leader>mm", "<cmd>RenderMarkdown toggle<CR>", { desc = "Markdown: toggle rendering" })

-- Browser preview, for what extmarks physically cannot draw: mermaid diagrams,
-- KaTeX, exact table/image layout. Pure Lua, no Node or Deno runtime to rot.
-- Scroll stays synced, so this is the Rider split-preview flow with the browser
-- as the read-only pane and nvim still the editor.
require("livepreview.config").set({
	port = 5500,
	browser = "default",
	dynamic_root = false,
	sync_scroll = true,
	picker = "telescope",
})

vim.keymap.set("n", "<leader>mp", "<cmd>LivePreview start<CR>", { desc = "Markdown: preview in browser" })
vim.keymap.set("n", "<leader>mq", "<cmd>LivePreview close<CR>", { desc = "Markdown: stop browser preview" })

-- Reading prose wants soft wrap on word boundaries; code defaults do not.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
	end,
})

-- Gitsigns
-- Symbols instead of coloured bars, so added / changed / deleted read apart
-- without relying on colour. Hidden until review mode (<leader>gh) shows them.
require("gitsigns").setup({
	signcolumn = false,
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	-- Staged means reviewed, so staged lines carry no sign at all. The default
	-- dims them instead, which is too subtle to see that staging worked.
	signs_staged_enable = false,
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- nav + inline preview: deletions and changes render as virtual lines
		-- right where they happened. Pure additions show nothing extra, which
		-- is correct, the added lines are already on screen. No float pops.
		local function nav(dir)
			return function()
				gs.nav_hunk(dir, { target = "unstaged" })
				gs.preview_hunk_inline()
			end
		end
		map("n", "]a", nav("next"), "Next hunk")
		map("n", "[a", nav("prev"), "Previous hunk")

		-- Review mode: signs, line colour and changed words, all together. Off by
		-- default so the screen stays clean while coding. Staging clears the marks,
		-- so what stays lit is unreviewed.
		map("n", "<leader>gh", function()
			local on = gs.toggle_signs()
			gs.toggle_linehl(on)
			gs.toggle_word_diff(on)
		end, "Review mode: show/hide change marks")

		map("n", "<leader>gp", gs.preview_hunk_inline, "Preview hunk inline")
		map("n", "<leader>gP", gs.preview_hunk, "Preview hunk in float")

		-- y/n: accept (stage) or reject (discard). stage_hunk toggles, so on an
		-- already accepted hunk it would silently unstage it, and staged lines have
		-- no signs to warn you. <leader>gy therefore only ever accepts, and undoing
		-- an accept is its own key, <leader>gu. That works per file: undoing a single
		-- accepted hunk needs staged-hunk tracking, which signs_staged_enable turns off.
		local function unstaged_hunk_at_cursor()
			local line = vim.fn.line(".")
			for _, h in ipairs(gs.get_hunks(bufnr) or {}) do
				local first = math.max(h.added.start, 1)
				if line >= first and line <= first + math.max(h.added.count, 1) - 1 then
					return true
				end
			end
			return false
		end
		map("n", "<leader>gy", function()
			if not unstaged_hunk_at_cursor() then
				return vim.notify("Nothing to accept here")
			end
			gs.stage_hunk()
		end, "Accept hunk (stage)")
		map("n", "<leader>gu", gs.reset_buffer_index, "Undo all accepts in this file (unstage)")
		map("v", "<leader>gy", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Accept selected lines")
		map("n", "<leader>gY", gs.stage_buffer, "Accept whole file")

		map("n", "<leader>gn", gs.reset_hunk, "Reject hunk (discard)")
		map("v", "<leader>gn", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Reject selected lines")
		map("n", "<leader>gN", gs.reset_buffer, "Reject all changes in file")

		map("n", "<leader>gd", gs.diffthis, "Diff against index")
		map("n", "<leader>gD", function()
			gs.diffthis("~")
		end, "Diff against last commit")
		map("n", "<leader>gb", function()
			gs.blame_line({ full = true })
		end, "Blame line")
		map("n", "<leader>gq", function()
			gs.setqflist("all")
		end, "All hunks in repo to quickfix")

		map({ "o", "x" }, "ih", gs.select_hunk, "Hunk text object")
	end,
})

-- Review loop: jump between files Copilot touched
vim.keymap.set("n", "<leader>gg", builtin.git_status, { desc = "Changed files" })

-- The git index is the ledger: unstaged means unreviewed. <leader>gr lists
-- every file still carrying unreviewed changes, <leader>gy stages a hunk once
-- you have read it, and re-running <leader>gr shows a shorter list. gitsigns
-- only knows about tracked files, so brand new ones are collected separately.
local function unreviewed()
	local function git(args)
		local res = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
		return res.code == 0 and vim.split(res.stdout or "", "\n", { trimempty = true }) or {}
	end

	local root = git({ "rev-parse", "--show-toplevel" })[1]
	if not root then
		return nil
	end

	local items = {}
	local function add(paths, label)
		for _, p in ipairs(paths) do
			table.insert(items, { filename = root .. "/" .. p, lnum = 1, col = 1, text = label })
		end
	end
	add(git({ "-C", root, "diff", "--name-only", "--diff-filter=d" }), "changed")
	add(git({ "-C", root, "ls-files", "--others", "--exclude-standard" }), "new file")
	-- A deleted file has no buffer to jump to, so it is listed as text only.
	-- Read it in diffview (<leader>gv) and accept it with `git rm` or lazygit.
	for _, p in ipairs(git({ "-C", root, "diff", "--name-only", "--diff-filter=D" })) do
		table.insert(items, { text = "deleted: " .. p })
	end
	return items
end

vim.keymap.set("n", "<leader>gr", function()
	local items = unreviewed()
	if not items then
		return vim.notify("not a git repo", vim.log.levels.ERROR)
	end
	if #items == 0 then
		return vim.notify("Nothing left to review")
	end
	vim.fn.setqflist({}, " ", { items = items, title = "Unreviewed (" .. #items .. ")" })
	vim.cmd("copen")
end, { desc = "Review: files with unreviewed changes" })

vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<CR>", { desc = "Review: diffview" })
vim.keymap.set("n", "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Review: history of this file" })
-- Random access into the review list: type the filename instead of scrolling.
vim.keymap.set("n", "<leader>gl", builtin.quickfix, { desc = "Review: jump to a file in the list" })
