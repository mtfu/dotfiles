-- kdiff3-style conflict resolution, for `git mergetool` (nvimdiff) or any file with
-- conflict markers. Works on the markers in the current buffer, so run it in MERGED.
-- The A (BASE) sign needs the `|||||||` section, i.e. merge.conflictStyle = diff3 or zdiff3.

local function conflicts(buf)
	local found, cur = {}, nil
	for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		if line:match("^<<<<<<<") then
			cur = { start = i }
		elseif cur and line:match("^|||||||") then
			cur.base = i
		elseif cur and line:match("^=======$") then
			cur.sep = i
		elseif cur and cur.sep and line:match("^>>>>>>>") then
			cur.finish = i
			table.insert(found, cur)
			cur = nil
		end
	end
	return found
end

local function side_lines(buf, c, side)
	local from, to
	if side == "local+remote" or side == "remote+local" then
		local a, b = side_lines(buf, c, "local"), side_lines(buf, c, "remote")
		if side == "remote+local" then
			a, b = b, a
		end
		return vim.list_extend(a, b)
	elseif side == "local" then
		from, to = c.start + 1, (c.base or c.sep) - 1
	else
		from, to = c.sep + 1, c.finish - 1
	end
	return vim.api.nvim_buf_get_lines(buf, from - 1, to, false)
end

local function take(c, side)
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, c.start - 1, c.finish, false, side_lines(buf, c, side))
end

local function take_current(side)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	for _, c in ipairs(conflicts(0)) do
		if row >= c.start and row <= c.finish then
			take(c, side)
			vim.api.nvim_win_set_cursor(0, { math.min(c.start, vim.api.nvim_buf_line_count(0)), 0 })
			return
		end
	end
	vim.notify("Cursor is not inside a conflict", vim.log.levels.WARN)
end

-- Compares sections ignoring whitespace: runs collapse to one space, edges and blank lines drop.
local function normalized(lines)
	local out = {}
	for _, line in ipairs(lines) do
		line = vim.trim((line:gsub("%s+", " ")))
		if line ~= "" then
			table.insert(out, line)
		end
	end
	return table.concat(out, "\n")
end

-- Which side resolves a conflict on its own, kdiff3-style, or nil when both sides really changed it:
-- sides equal apart from whitespace, or one side only changed whitespace compared with BASE.
local function auto_side(buf, c)
	local l, r = normalized(side_lines(buf, c, "local")), normalized(side_lines(buf, c, "remote"))
	if l == r then
		return "local"
	end
	if not c.base then
		return nil
	end
	local b = normalized(vim.api.nvim_buf_get_lines(buf, c.base, c.sep - 1, false))
	if l == b then
		return "remote"
	elseif r == b then
		return "local"
	end
end

local function auto_solve()
	local all = conflicts(0)
	if #all == 0 then
		return vim.notify("No conflicts left", vim.log.levels.INFO)
	end
	local solved = 0
	-- Bottom-up so earlier line numbers stay valid.
	for i = #all, 1, -1 do
		local side = auto_side(0, all[i])
		if side then
			take(all[i], side)
			solved = solved + 1
		end
	end
	vim.notify(("Auto-solved %d of %d conflict(s)"):format(solved, #all))
end

local function jump(forward)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local all = conflicts(0)
	local first, last = 1, #all
	if not forward then
		first, last = #all, 1
	end
	for i = first, last, forward and 1 or -1 do
		local start = all[i].start
		if (forward and start > row) or (not forward and start < row) then
			vim.api.nvim_win_set_cursor(0, { start, 0 })
			vim.cmd("normal! zz")
			return
		end
	end
	vim.notify(#all == 0 and "No conflicts left" or "No more conflicts in that direction", vim.log.levels.INFO)
end

local map = vim.keymap.set
map("n", "]x", function() jump(true) end, { desc = "Conflict: next" })
map("n", "[x", function() jump(false) end, { desc = "Conflict: previous" })
map("n", "<leader>2", function() take_current("local") end, { desc = "Conflict: take LOCAL (B)" })
map("n", "<leader>3", function() take_current("remote") end, { desc = "Conflict: take REMOTE (C)" })
map("n", "<leader>4", function() take_current("local+remote") end, { desc = "Conflict: take LOCAL then REMOTE" })
map("n", "<leader>5", function() take_current("remote+local") end, { desc = "Conflict: take REMOTE then LOCAL" })
map("n", "<leader>xa", auto_solve, { desc = "Conflicts: auto-solve whitespace-only ones" })

-- Source labels, as in kdiff3: A = BASE, B = LOCAL, C = REMOTE.
-- MERGED gets an A/B/C sign on every line inside a conflict; the LOCAL/BASE/REMOTE windows of
-- `git mergetool` get a winbar naming the commit they show.
local ns = vim.api.nvim_create_namespace("conflict_sources")
local tags = {
	base = { "A", "ConflictSourceA" },
	["local"] = { "B", "ConflictSourceB" },
	remote = { "C", "ConflictSourceC" },
}

local function set_highlights()
	vim.api.nvim_set_hl(0, "ConflictSourceA", { link = "DiagnosticInfo", default = true })
	vim.api.nvim_set_hl(0, "ConflictSourceB", { link = "DiagnosticOk", default = true })
	vim.api.nvim_set_hl(0, "ConflictSourceC", { link = "DiagnosticWarn", default = true })
end
set_highlights()

local function decorate(buf)
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, c in ipairs(conflicts(buf)) do
		local sections = {
			{ "local", c.start + 1, (c.base or c.sep) - 1 },
			{ "remote", c.sep + 1, c.finish - 1 },
		}
		if c.base then
			table.insert(sections, { "base", c.base + 1, c.sep - 1 })
		end
		for _, s in ipairs(sections) do
			local tag = tags[s[1]]
			for row = s[2], s[3] do
				-- Above gitsigns (priority 6), so the source wins the sign column.
				vim.api.nvim_buf_set_extmark(buf, ns, row - 1, 0, { sign_text = tag[1], sign_hl_group = tag[2], priority = 20 })
			end
		end
	end
end

local function git(args)
	local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
	return result.code == 0 and vim.trim(result.stdout) or nil
end

local function describe(rev)
	local name = git({ "name-rev", "--name-only", "--no-undefined", "--exclude=refs/tags/*", rev })
	local sha = git({ "rev-parse", "--short", rev })
	if not sha then
		return nil
	end
	return name and ("%s %s"):format(name:gsub("^remotes/", ""), sha) or sha
end

local sources
local function get_sources()
	if sources then
		return sources
	end
	local branch = git({ "branch", "--show-current" })
	local head = describe("HEAD")
	sources = { LOCAL = (branch and branch ~= "") and ("%s %s"):format(branch, git({ "rev-parse", "--short", "HEAD" })) or head }
	if git({ "rev-parse", "-q", "--verify", "MERGE_HEAD" }) then
		sources.REMOTE = describe("MERGE_HEAD")
		local base = git({ "merge-base", "HEAD", "MERGE_HEAD" })
		sources.BASE = base and git({ "rev-parse", "--short", base })
	else
		-- Rebase and cherry-pick replay one commit: LOCAL is the target, REMOTE the commit, BASE its parent.
		for _, ref in ipairs({ "REBASE_HEAD", "CHERRY_PICK_HEAD" }) do
			if git({ "rev-parse", "-q", "--verify", ref }) then
				sources.REMOTE = describe(ref)
				sources.BASE = git({ "rev-parse", "--short", ref .. "^" })
				break
			end
		end
	end
	return sources
end

local roles = { BASE = "base", LOCAL = "local", REMOTE = "remote" }

local function winbars()
	local found, diff_wins = false, {}
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local name = vim.fs.basename(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)))
		local role = name:match("_(%u+)_%d+[^_]*$")
		if role and roles[role] then
			found = true
			local tag = tags[roles[role]]
			local source = get_sources()[role]
			local text = source and ("%s · %s"):format(role, source) or role
			vim.wo[win].winbar = ("%%#%s# %s %%* %s"):format(tag[2], tag[1], text:gsub("%%", "%%%%"))
		elseif vim.wo[win].diff then
			table.insert(diff_wins, win)
		end
	end
	if found then
		for _, win in ipairs(diff_wins) do
			vim.wo[win].winbar = " MERGED"
		end
	end
end

local group = vim.api.nvim_create_augroup("ConflictSources", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "InsertLeave", "BufWritePost" }, {
	group = group,
	callback = function(args) decorate(args.buf) end,
})
vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "OptionSet" }, {
	group = group,
	callback = function(args)
		if args.event ~= "OptionSet" or args.match == "diff" then
			winbars()
		end
	end,
})