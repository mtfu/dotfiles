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

-- live-preview checks the port by starting PowerShell (profile included) on
-- every start, which froze nvim for seconds with no feedback, and on a busy
-- port it opened the browser against the other server anyway (404). Check the
-- port here instead, in about a millisecond, and take the next free one.
require("livepreview.utils").processes_listening_on_port = function()
	return {}
end

local function free_port(from)
	for port = from, from + 20 do
		local tcp = vim.uv.new_tcp()
		-- On Windows libuv reports a bind conflict only at listen.
		local ok = tcp:bind("127.0.0.1", port) and tcp:listen(1, function() end)
		tcp:close()
		if ok == 0 then
			return port
		end
	end
end

-- Also run by the PowerShell `mb` function in a headless nvim.
local function preview_start()
	local port = free_port(5500)
	if not port then
		return vim.notify("Markdown preview: no free port in 5500-5520", vim.log.levels.ERROR)
	end
	require("livepreview.config").set({ port = port })
	vim.notify(("Markdown preview on port %d, opening browser…"):format(port))
	vim.cmd("LivePreview start")
end
vim.api.nvim_create_user_command("MarkdownPreview", preview_start, { desc = "Markdown: preview on a free port" })

vim.keymap.set("n", "<leader>mb", function()
	local lp = require("livepreview")
	if lp.is_running() then
		lp.close()
		return vim.notify("Markdown preview stopped")
	end
	preview_start()
end, { desc = "Markdown: toggle browser preview" })
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

-- The git index is the ledger: unstaged means unreviewed. <leader>gr lists
-- every file still carrying unreviewed changes, gy stages a hunk once
-- you have read it, and re-running <leader>gr shows a shorter list. `git diff`
-- only lists tracked files, so brand new ones are collected separately.
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
	-- Read and accept it in lazygit.
	for _, p in ipairs(git({ "-C", root, "diff", "--name-only", "--diff-filter=D" })) do
		table.insert(items, { text = "deleted: " .. p })
	end
	return items
end

-- Review mode: a PR-style view in place. Signs, line colour, changed words and
-- removed lines as red virtual lines, all together, and they stay put as you
-- move. Off while coding so the screen stays clean; <leader>gr turns it on.
-- It already draws removed lines, so goto_hunk doesn't preview them again.
local review_mode = false

local function set_review_mode(on)
	local gs = require("gitsigns")
	review_mode = on
	if on then
		require("gitsigns.actions.preview").clear_preview_inline(vim.api.nvim_get_current_buf())
	end
	gs.toggle_signs(on)
	gs.toggle_linehl(on)
	gs.toggle_word_diff(on)
	gs.toggle_deleted(on)
end

-- Both calls are async: preview only once the cursor has landed, or it renders
-- at the old hunk and the move's CursorMoved clears it.
local function goto_hunk(dir)
	local gs = require("gitsigns")
	gs.nav_hunk(dir, { target = "unstaged" }, function()
		if not review_mode then
			gs.preview_hunk_inline()
		end
	end)
end

-- PR-style colours: new code green, removed code red, changed words a stronger
-- shade of the same. The defaults link word diff to TermCursor (reverse video),
-- which is unreadable on top of line colour.
local function review_highlights()
	local hl = function(name, val)
		vim.api.nvim_set_hl(0, name, val)
	end
	hl("GitSignsAddLn", { bg = "#2f3a1e" })
	hl("GitSignsChangeLn", { link = "GitSignsAddLn" })
	hl("GitSignsDeleteVirtLn", { bg = "#3d1f1e" })
	hl("GitSignsVirtLnum", { fg = "#7c6f64", bg = "#3d1f1e" })
	hl("GitSignsAddInline", { bg = "#4b5e22", bold = true })
	hl("GitSignsChangeInline", { link = "GitSignsAddInline" })
	hl("GitSignsDeleteInline", { bg = "#6b2a27", bold = true })
	hl("GitSignsAddLnInline", { link = "GitSignsAddInline" })
	hl("GitSignsChangeLnInline", { link = "GitSignsAddInline" })
	hl("GitSignsDeleteLnInline", { link = "GitSignsDeleteInline" })
	hl("GitSignsDeleteVirtLnInLine", { link = "GitSignsDeleteInline" })
end
review_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = review_highlights })

-- Gitsigns
-- Symbols instead of coloured bars, so added / changed / deleted read apart
-- without relying on colour. Hidden until review mode (<leader>gh) shows them.
require("gitsigns").setup({
	signcolumn = false,
	-- Files an agent creates are untracked. Without this gitsigns skips them, so
	-- review mode and the accept/reject keys don't exist in their buffers.
	attach_to_untracked = true,
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
	-- Staged lines stay visible, but with their own mark. Hiding them made an
	-- accepted file look identical to an untouched one, which matters when an
	-- agent edits files you never opened: empty would mean both "nothing
	-- happened" and "reviewed and accepted". The default dim is too subtle to
	-- tell apart, so reviewed hunks get a check of their own instead.
	signs_staged_enable = true,
	signs_staged = {
		add = { text = "✓" },
		change = { text = "✓" },
		delete = { text = "✓" },
		topdelete = { text = "✓" },
		changedelete = { text = "✓" },
	},
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
				goto_hunk(dir)
			end
		end
		map("n", "]a", nav("next"), "Next hunk")
		map("n", "[a", nav("prev"), "Previous hunk")

		-- Staging clears the marks, so in review mode what stays lit is unreviewed.
		map("n", "<leader>gh", function()
			set_review_mode(not review_mode)
		end, "Review mode: show/hide changes PR-style")

		-- y/n: accept (stage) or reject (discard). stage_hunk toggles, so on an
		-- already accepted hunk it would silently unstage it, and staged lines have
		-- no signs to warn you. gy therefore only ever accepts, and undoing an accept
		-- is its own key: <leader>gu for the ✓ hunk under the cursor, <leader>gU for the file.
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
		map("n", "gy", function()
			if not unstaged_hunk_at_cursor() then
				return vim.notify("Nothing to accept here")
			end
			gs.stage_hunk(nil, nil, function()
				vim.schedule(function()
					if #(gs.get_hunks(bufnr) or {}) > 0 then
						nav("next")()
					end
				end)
			end)
		end, "Accept hunk (stage) and go to the next one in this file")
		local function in_head()
			local path = vim.api.nvim_buf_get_name(bufnr)
			local cmd = { "git", "-C", vim.fs.dirname(path), "cat-file", "-e", "HEAD:./" .. vim.fs.basename(path) }
			return vim.system(cmd):wait().code == 0
		end
		-- Off an unstaged hunk, stage_hunk unstages the staged hunk under the cursor.
		-- A new file's staged hunk is its whole index copy, and unstaging that would
		-- leave an empty file staged, so take the file out of the index instead.
		map("n", "<leader>gu", function()
			if unstaged_hunk_at_cursor() then
				return vim.notify("Not accepted yet; gy accepts it")
			end
			if in_head() then
				gs.stage_hunk()
			else
				gs.reset_buffer_index()
			end
		end, "Undo accept of this hunk (unstage)")
		map("n", "<leader>gU", gs.reset_buffer_index, "Undo all accepts in this file (unstage)")
		map("v", "gy", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Accept selected lines")
		map("n", "gY", gs.stage_buffer, "Accept whole file")

		map("n", "<leader>gn", gs.reset_hunk, "Reject hunk (discard)")
		map("v", "<leader>gn", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Reject selected lines")
		map("n", "<leader>gN", gs.reset_buffer, "Reject all changes in file")

		map({ "o", "x" }, "ih", gs.select_hunk, "Hunk text object")
	end,
})

-- Review loop: jump between files Copilot touched
vim.keymap.set("n", "<leader>gg", builtin.git_status, { desc = "Changed files" })

vim.keymap.set("n", "<leader>gr", function()
	local items = unreviewed()
	if not items then
		return vim.notify("not a git repo", vim.log.levels.ERROR)
	end
	if #items == 0 then
		return vim.notify("Nothing left to review")
	end
	vim.fn.setqflist({}, " ", { items = items, title = "Unreviewed (" .. #items .. ")" })
	set_review_mode(true)
	vim.cmd("copen")
end, { desc = "Review: files with unreviewed changes" })

-- Opening a file from the review list (]q, Enter in quickfix) lands on its first
-- unreviewed hunk. gitsigns diffs asynchronously, so a file it hasn't diffed yet
-- jumps on its first GitSignsUpdate instead.
local function first_hunk(buf)
	local gs = require("gitsigns")
	if vim.api.nvim_get_current_buf() ~= buf or #(gs.get_hunks(buf) or {}) == 0 then
		return
	end
	vim.b[buf].review_pending = nil
	goto_hunk("first")
end

local review = vim.api.nvim_create_augroup("review_first_hunk", { clear = true })
-- Set when a drop moved the current entry onto a file you haven't opened from
-- there yet, so ]q opens that entry instead of skipping past it. Keyed to the
-- list and entry, so jumping elsewhere or moving through the list voids it.
local unvisited
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = review,
	callback = function(ev)
		vim.schedule(function()
			local qf = vim.fn.getqflist({ title = 0, idx = 0, items = 0 })
			local item = qf.items[qf.idx]
			if vim.startswith(qf.title, "Unreviewed") and item and item.bufnr == ev.buf then
				unvisited = nil
				vim.b[ev.buf].review_pending = true
				first_hunk(ev.buf)
			end
		end)
	end,
})
-- A file with nothing left to review leaves the list, so the list is the
-- progress bar. The current entry moves to the file that followed it, or to the
-- one before it when the last file left.
local function drop_reviewed(buf)
	local qf = vim.fn.getqflist({ id = 0, title = 0, idx = 0, items = 0 })
	if not vim.startswith(qf.title, "Unreviewed") then
		return
	end
	for i, item in ipairs(qf.items) do
		if item.bufnr == buf then
			vim.b[buf].review_dropped = item.text
			table.remove(qf.items, i)
			local idx = math.min(qf.idx > i and qf.idx - 1 or qf.idx, math.max(#qf.items, 1))
			vim.fn.setqflist({}, "r", { id = qf.id, items = qf.items, idx = idx, title = "Unreviewed (" .. #qf.items .. ")" })
			if #qf.items == 0 then
				vim.notify("Nothing left to review")
			elseif i == qf.idx then
				unvisited = { id = qf.id, idx = idx }
			elseif unvisited and unvisited.id == qf.id and unvisited.idx == qf.idx then
				unvisited.idx = idx
			end
			return
		end
	end
end

-- Undoing an accept (<leader>gu/gU) makes a dropped file unreviewed again, so it
-- comes back. The file on screen becomes the current entry again, so ]q carries on.
local function restore_reviewed(buf)
	local text = vim.b[buf].review_dropped
	vim.b[buf].review_dropped = nil
	local qf = vim.fn.getqflist({ id = 0, title = 0, idx = 0, items = 0 })
	if not vim.startswith(qf.title, "Unreviewed") then
		return
	end
	for _, item in ipairs(qf.items) do
		if item.bufnr == buf then
			return
		end
	end
	local entry = { bufnr = buf, lnum = 1, col = 1, text = text }
	local idx = math.max(qf.idx, 1)
	if buf == vim.api.nvim_get_current_buf() then
		table.insert(qf.items, math.min(idx, #qf.items + 1), entry)
		unvisited = nil
	else
		table.insert(qf.items, entry)
	end
	vim.fn.setqflist({}, "r", { id = qf.id, items = qf.items, idx = idx, title = "Unreviewed (" .. #qf.items .. ")" })
end

vim.api.nvim_create_autocmd("User", {
	group = review,
	pattern = "GitSignsUpdate",
	callback = function(ev)
		local buf = ev.data and ev.data.buffer
		if not buf then
			return
		end
		if vim.b[buf].review_pending then
			first_hunk(buf)
		end
		-- Gitsigns reports 0 hunks once before its first diff, so only a file that
		-- had hunks and now has none counts as reviewed.
		local count = #(require("gitsigns").get_hunks(buf) or {})
		if count > 0 then
			vim.b[buf].review_had_hunks = true
			if vim.b[buf].review_dropped then
				restore_reviewed(buf)
			end
		elseif vim.b[buf].review_had_hunks then
			vim.b[buf].review_had_hunks = nil
			drop_reviewed(buf)
		end
	end,
})

-- After a drop, ]q opens the new current entry (see unvisited) and counts on
-- from there. Anywhere else, including the quickfix window, it is a plain :cnext.
vim.keymap.set("n", "]q", function()
	local qf = vim.fn.getqflist({ id = 0, idx = 0, size = 0 })
	local cmd = vim.v.count1 .. "cnext"
	if unvisited and unvisited.id == qf.id and unvisited.idx == qf.idx then
		cmd = math.min(qf.idx + vim.v.count1 - 1, qf.size) .. "cc"
	end
	unvisited = nil
	local ok, err = pcall(vim.cmd, cmd)
	if not ok then
		vim.notify(err:gsub("^.-:E", "E"), vim.log.levels.WARN)
	end
end, { desc = "Next quickfix entry" })
-- A fully accepted file never gets a hunk; don't jump later when you edit it.
vim.api.nvim_create_autocmd("BufLeave", {
	group = review,
	callback = function(ev)
		vim.b[ev.buf].review_pending = nil
	end,
})

-- Random access into the review list: type the filename instead of scrolling.
vim.keymap.set("n", "<leader>gl", builtin.quickfix, { desc = "Review: jump to a file in the list" })
