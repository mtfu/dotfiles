-- Send file references from nvim into a herdr pane running an agent.
-- `herdr pane send-text` writes into the pane's stdin without submitting,
-- so the reference lands in the agent prompt and stays editable.

local M = {}

-- Copilot CLI resolves `@path` as a file mention. A line range is plain text,
-- so the mention prefix is only used when sending a whole file.
M.prefix = "@"

-- The chosen agent ({ pane_id, cwd, ... }), remembered until a send fails.
local target = nil

local function herdr(args)
	local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait()
	if res.code ~= 0 then
		return nil, (res.stderr or res.stdout or ""):gsub("%s+$", "")
	end
	return res.stdout
end

local function agents()
	local out, err = herdr({ "agent", "list" })
	if not out then
		return nil, err
	end
	local ok, decoded = pcall(vim.json.decode, out)
	if not ok or type(decoded) ~= "table" or not decoded.result then
		return nil, "could not parse `herdr agent list`"
	end
	local own = vim.env.HERDR_PANE_ID
	local list = {}
	for _, agent in ipairs(decoded.result.agents or {}) do
		if agent.pane_id and agent.pane_id ~= own then
			table.insert(list, agent)
		end
	end
	return list
end

local function workspace_of(pane_id)
	return pane_id and pane_id:match("^([^:]+):")
end

local function label(agent)
	return table.concat({
		agent.pane_id,
		agent.agent or "agent",
		agent.agent_status or "unknown",
		agent.cwd or "",
	}, "  ")
end

--- Resolve a target agent, asking only when the choice is ambiguous.
local function resolve(callback)
	if target then
		return callback(target)
	end

	local list, err = agents()
	if not list then
		return vim.notify(err, vim.log.levels.ERROR)
	end
	if #list == 0 then
		return vim.notify("herdr: no other agent panes", vim.log.levels.WARN)
	end

	local own_ws = workspace_of(vim.env.HERDR_PANE_ID)
	if own_ws then
		local same = vim.tbl_filter(function(a)
			return workspace_of(a.pane_id) == own_ws
		end, list)
		if #same > 0 then
			list = same
		end
	end

	if #list == 1 then
		target = list[1]
		return callback(target)
	end

	vim.ui.select(list, { prompt = "herdr target pane", format_item = label }, function(choice)
		if choice then
			target = choice
			callback(target)
		end
	end)
end

--- `path` relative to the target agent's cwd when it lives under it.
local function relative(agent, path)
	path = path:gsub("\\", "/")
	if agent.cwd then
		local cwd = agent.cwd:gsub("\\", "/"):gsub("/$", "")
		local prefix = cwd:lower() .. "/"
		if path:lower():sub(1, #prefix) == prefix then
			path = path:sub(#prefix + 1)
		end
	end
	return path
end

local function location(path, first, last)
	return first == last and string.format("%s:%d", path, first) or string.format("%s:%d-%d", path, first, last)
end

--- Path of the current buffer, relative to the target agent's cwd when possible.
local function reference(agent, first, last)
	local path = vim.fn.expand("%:p")
	if path == "" then
		return nil
	end
	path = relative(agent, path)
	return (first and last) and location(path, first, last) or M.prefix .. path
end

--- Send the current file (and optional line range) to the target pane.
--- With a question, both are submitted as a prompt; without, the reference is
--- left unsubmitted in the agent's input to keep typing there.
--- Always copies what was sent to the clipboard as a manual-paste fallback.
function M.send(first, last, question)
	resolve(function(agent)
		local pane_id = agent.pane_id
		local ref = reference(agent, first, last)
		if not ref then
			return vim.notify("herdr: buffer has no file", vim.log.levels.WARN)
		end

		local args = { "pane", "send-text", pane_id, ref .. " " }
		if question and question ~= "" then
			ref = ref .. " " .. question
			args = { "agent", "prompt", pane_id, ref }
		end
		pcall(vim.fn.setreg, "+", ref)

		local _, err = herdr(args)
		if err then
			target = nil
			return vim.notify("herdr: " .. err, vim.log.levels.ERROR)
		end
		vim.notify(string.format("%s -> %s", ref, pane_id))
	end)
end

--- Forget the remembered pane so the next send re-prompts.
function M.pick()
	target = nil
	resolve(function(agent)
		vim.notify("herdr target: " .. agent.pane_id)
	end)
end

-- Review comments: annotate lines while reading, then send them all as one prompt.
-- Each comment is an extmark, so it follows its lines as the buffer is edited.
-- Comments live only in this nvim session; sending clears them.

local ns = vim.api.nvim_create_namespace("herdr_review")
-- buf -> extmark id -> text. Extmark ids are only unique within a buffer.
local notes = {}

local function note_at(buf, row)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { overlap = true })
	return marks[1] and marks[1][1]
end

--- Add a comment on lines first..last (1-based), or edit the one already there.
--- Submitting an empty edit deletes the comment.
function M.comment(first, last)
	local buf = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_name(buf) == "" then
		return vim.notify("herdr: buffer has no file", vim.log.levels.WARN)
	end

	local id = note_at(buf, first - 1)
	notes[buf] = notes[buf] or {}
	local old = id and notes[buf][id]
	local prompt = old and "Edit comment (empty deletes): " or "Comment: "
	vim.ui.input({ prompt = prompt, default = old }, function(text)
		if not text then
			return
		end
		text = vim.trim(text)
		if text == "" then
			if id then
				vim.api.nvim_buf_del_extmark(buf, ns, id)
				notes[buf][id] = nil
			end
			return
		end

		local row, end_row, end_col
		if id then
			local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
			row, end_row, end_col = mark[1], mark[3].end_row, mark[3].end_col
		else
			row, end_row = first - 1, last - 1
			end_col = #vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, true)[1]
		end
		id = vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
			id = id,
			end_row = end_row,
			end_col = end_col,
			sign_text = "»",
			sign_hl_group = "DiagnosticInfo",
			virt_text = { { "  " .. text, "Comment" } },
			virt_text_pos = "eol",
			-- Hidden (and skipped on send) if its lines are deleted; undo restores it.
			invalidate = true,
		})
		notes[buf][id] = text
	end)
end

--- Current position of every live comment, sorted by file and line.
local function collect()
	local items = {}
	for buf, by_id in pairs(notes) do
		if vim.api.nvim_buf_is_valid(buf) then
			for id, text in pairs(by_id) do
				local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
				if mark[1] and not mark[3].invalid then
					table.insert(items, {
						path = vim.api.nvim_buf_get_name(buf),
						first = mark[1] + 1,
						last = mark[3].end_row + 1,
						text = text,
					})
				end
			end
		end
	end
	table.sort(items, function(a, b)
		return a.path == b.path and a.first < b.first or a.path < b.path
	end)
	return items
end

--- Submit all comments to the target agent as one prompt.
function M.send_review()
	local items = collect()
	if #items == 0 then
		return vim.notify("herdr: no review comments", vim.log.levels.WARN)
	end

	resolve(function(agent)
		local lines = { "Address these review comments:", "" }
		for i, item in ipairs(items) do
			local loc = location(relative(agent, item.path), item.first, item.last)
			table.insert(lines, string.format("%d. %s - %s", i, loc, item.text))
		end
		local msg = table.concat(lines, "\n")
		pcall(vim.fn.setreg, "+", msg)

		-- `agent prompt` pastes the text as one block and then presses Enter, so the
		-- newlines do not submit early. It refuses while the agent awaits an approval.
		local _, err = herdr({ "agent", "prompt", agent.pane_id, msg })
		if err then
			target = nil
			return vim.notify("herdr: " .. err, vim.log.levels.ERROR)
		end

		for buf in pairs(notes) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
			end
		end
		notes = {}
		vim.notify(string.format("%d review comment(s) -> %s", #items, agent.pane_id))
	end)
end

vim.keymap.set("n", "<leader>hc", function()
	local line = vim.fn.line(".")
	M.comment(line, line)
end, { desc = "herdr: add/edit review comment" })

vim.keymap.set("v", "<leader>hc", function()
	local a, b = vim.fn.line("v"), vim.fn.line(".")
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	M.comment(math.min(a, b), math.max(a, b))
end, { desc = "herdr: review comment on selection" })

vim.keymap.set("n", "<leader>hs", M.send_review, { desc = "herdr: send review comments to agent pane" })

--- Ask for a question in nvim, then send it with the file (and optional range) reference.
--- An empty question sends just the reference, unsubmitted; <Esc> cancels.
function M.ask(first, last)
	if vim.fn.expand("%") == "" then
		return vim.notify("herdr: buffer has no file", vim.log.levels.WARN)
	end
	local what = vim.fn.expand("%:t")
	if first then
		what = location(what, first, last)
	end
	vim.ui.input({ prompt = "Ask about " .. what .. " (empty: just the ref): " }, function(question)
		if question then
			M.send(first, last, vim.trim(question))
		end
	end)
end

-- <leader>hh is Telescope recent files (editor.lua), so file refs use <leader>hf.
vim.keymap.set("n", "<leader>hf", function()
	M.ask()
end, { desc = "herdr: ask agent about this file" })

vim.keymap.set("n", "<leader>hl", function()
	local line = vim.fn.line(".")
	M.ask(line, line)
end, { desc = "herdr: ask agent about the current line" })

vim.keymap.set("v", "<leader>hl", function()
	local a, b = vim.fn.line("v"), vim.fn.line(".")
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	M.ask(math.min(a, b), math.max(a, b))
end, { desc = "herdr: ask agent about the selected range" })

vim.keymap.set("n", "<leader>hp", M.pick, { desc = "herdr: pick target agent pane" })

return M
