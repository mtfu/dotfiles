-- Global change list across buffers, like Rider's JumpToLastChange / JumpToNextChange.
-- Positions are stored as extmarks so they follow later edits. The file and last known
-- position are kept too, so a closed buffer is reopened when jumping to it.
local ns = vim.api.nvim_create_namespace("global_changes")
local max_entries = 100
local changes = {} -- { buf, id, file, row, col }, oldest first
local index = nil -- position while navigating; nil = not navigating

local function loaded(entry)
	return vim.api.nvim_buf_is_valid(entry.buf) and vim.api.nvim_buf_is_loaded(entry.buf)
end

-- Refresh the cached position from the extmark while the buffer is loaded
local function pos(entry)
	if loaded(entry) then
		local mark = vim.api.nvim_buf_get_extmark_by_id(entry.buf, ns, entry.id, {})
		if mark[1] then
			entry.row, entry.col = mark[1] + 1, mark[2]
		end
	end
	return entry.row, entry.col
end

local function remove(i)
	local entry = table.remove(changes, i)
	if loaded(entry) then
		pcall(vim.api.nvim_buf_del_extmark, entry.buf, ns, entry.id)
	end
end

local function record()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype ~= "" then
		return
	end
	local mark = vim.api.nvim_buf_get_mark(buf, ".")
	if mark[1] == 0 then
		return
	end
	local row, col = mark[1], mark[2]

	-- Merge with the latest entry when editing nearby in the same buffer
	local last = changes[#changes]
	if last and last.buf == buf and math.abs(pos(last) - row) <= 1 then
		remove(#changes)
	end

	local id = vim.api.nvim_buf_set_extmark(buf, ns, row - 1, col, {})
	table.insert(changes, { buf = buf, id = id, file = vim.api.nvim_buf_get_name(buf), row = row, col = col })
	if #changes > max_entries then
		remove(1)
	end
	index = nil
end

local group = vim.api.nvim_create_augroup("GlobalChanges", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, { group = group, callback = record })

-- Save positions before the extmarks disappear with the buffer
vim.api.nvim_create_autocmd("BufUnload", {
	group = group,
	callback = function(args)
		for _, entry in ipairs(changes) do
			if entry.buf == args.buf then
				pos(entry)
			end
		end
	end,
})

-- Make sure the entry's buffer is loaded, reopening the file if needed
local function open(entry)
	if loaded(entry) then
		vim.api.nvim_set_current_buf(entry.buf)
		return true
	end
	if entry.file == "" or vim.fn.filereadable(entry.file) == 0 then
		return false
	end
	vim.cmd.edit(vim.fn.fnameescape(entry.file))
	local buf = vim.api.nvim_get_current_buf()
	-- Other entries for the same file get the new buffer and fresh extmarks too
	for _, e in ipairs(changes) do
		if e.file == entry.file and not loaded(e) then
			e.buf = buf
			local row = math.min(e.row, vim.api.nvim_buf_line_count(buf))
			e.id = vim.api.nvim_buf_set_extmark(buf, ns, row - 1, e.col, { strict = false })
		end
	end
	return true
end

local function jump(step)
	if #changes == 0 then
		return
	end
	local i = index
	if not i then
		if step > 0 then
			return
		end
		i = #changes + 1
		-- Skip the latest change if the cursor is already on it
		local last = changes[#changes]
		if last.buf == vim.api.nvim_get_current_buf() and pos(last) == vim.fn.line(".") then
			i = #changes
		end
	end

	while true do
		i = i + step
		if i < 1 or i > #changes then
			return
		end
		local entry = changes[i]
		vim.cmd("normal! m'")
		if open(entry) then
			index = i
			local row, col = pos(entry)
			row = math.min(row, vim.api.nvim_buf_line_count(entry.buf))
			pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
			vim.cmd("normal! zz")
			return
		end
		remove(i)
		if step > 0 then
			i = i - 1
		end
	end
end

vim.keymap.set("n", "g;", function()
	jump(-1)
end, { desc = "Previous change (all buffers)" })
vim.keymap.set("n", "g,", function()
	jump(1)
end, { desc = "Next change (all buffers)" })
