-- kdiff3-style conflict resolution, for `git mergetool` (nvimdiff) or any file with
-- conflict markers. Works on the markers in the current buffer, so run it in MERGED.
-- BASE needs the `|||||||` section, i.e. merge.conflictStyle = diff3 or zdiff3.

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
	if side == "local" then
		from, to = c.start + 1, (c.base or c.sep) - 1
	elseif side == "remote" then
		from, to = c.sep + 1, c.finish - 1
	else
		if not c.base then
			return nil
		end
		from, to = c.base + 1, c.sep - 1
	end
	return vim.api.nvim_buf_get_lines(buf, from - 1, to, false)
end

local function take(c, side)
	local buf = vim.api.nvim_get_current_buf()
	local lines = side_lines(buf, c, side)
	if not lines then
		vim.notify("No BASE section in this conflict (set merge.conflictStyle = zdiff3)", vim.log.levels.WARN)
		return false
	end
	vim.api.nvim_buf_set_lines(buf, c.start - 1, c.finish, false, lines)
	return true
end

local function take_current(side)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	for _, c in ipairs(conflicts(0)) do
		if row >= c.start and row <= c.finish then
			if take(c, side) then
				vim.api.nvim_win_set_cursor(0, { math.min(c.start, vim.api.nvim_buf_line_count(0)), 0 })
			end
			return
		end
	end
	vim.notify("Cursor is not inside a conflict", vim.log.levels.WARN)
end

local function take_all(side)
	local all = conflicts(0)
	if #all == 0 then
		vim.notify("No conflicts left", vim.log.levels.INFO)
		return
	end
	-- Bottom-up so earlier line numbers stay valid
	for i = #all, 1, -1 do
		if not take(all[i], side) then
			return
		end
	end
	vim.notify(("Resolved %d conflict(s) with %s"):format(#all, side:upper()))
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
map("n", "<leader>1", function() take_current("base") end, { desc = "Conflict: take BASE (A)" })
map("n", "<leader>2", function() take_current("local") end, { desc = "Conflict: take LOCAL (B)" })
map("n", "<leader>3", function() take_current("remote") end, { desc = "Conflict: take REMOTE (C)" })
map("n", "<leader>x1", function() take_all("base") end, { desc = "Conflicts: take BASE for all" })
map("n", "<leader>x2", function() take_all("local") end, { desc = "Conflicts: take LOCAL for all" })
map("n", "<leader>x3", function() take_all("remote") end, { desc = "Conflicts: take REMOTE for all" })
