-- Open the vault initiative note for the current repo or worktree.
-- The initiative is found by the checkout path recorded in its Stories.md or Tasks.md;
-- without a match, pick from all initiatives.

local M = {}

local vault = vim.env.OBSIDIAN_VAULT and vim.fs.normalize(vim.env.OBSIDIAN_VAULT)

local function norm(path)
	return path:gsub("/", "\\"):gsub("\\+$", ""):lower()
end

local function checkout_root()
	local res = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true, cwd = vim.fn.getcwd() }):wait()
	return res.code == 0 and vim.trim(res.stdout) or vim.fn.getcwd()
end

local function read(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local text = fd:read("*a")
	fd:close()
	return text
end

-- True when `needle` occurs in `text` as a whole path, so wt-x doesn't match wt-x-y or x.yarp
-- (a trailing sentence period still matches).
local function mentions(text, needle)
	local from = 1
	while true do
		local s, e = text:find(needle, from, true)
		if not s then
			return false
		end
		local after = text:sub(e + 1, e + 2)
		if not after:match("^[%w_%-]") and not after:match("^%.[%w_%-]") then
			return true
		end
		from = e + 1
	end
end

local function initiatives()
	local dirs = {}
	for name, kind in vim.fs.dir(vault .. "/AI") do
		if kind == "directory" and vim.uv.fs_stat(vault .. "/AI/" .. name .. "/START-HERE.md") then
			table.insert(dirs, name)
		end
	end
	table.sort(dirs)
	return dirs
end

local function matching()
	local needle = norm(checkout_root())
	local found = {}
	for _, name in ipairs(initiatives()) do
		for _, file in ipairs({ "Stories.md", "Tasks.md" }) do
			local text = read(vault .. "/AI/" .. name .. "/" .. file)
			if text and mentions(text:lower(), needle) then
				table.insert(found, name)
				break
			end
		end
	end
	return found
end

local function open(name, file)
	vim.cmd.edit(vim.fn.fnameescape(vault .. "/AI/" .. name .. "/" .. file))
	if file == "START-HERE.md" then
		vim.fn.search([[^## Open questions]], "cw")
	end
end

--- Open `file` ("START-HERE.md" or "Tasks.md") of the initiative this checkout belongs to.
function M.open(file)
	if not vault then
		return vim.notify("Set OBSIDIAN_VAULT to the vault folder", vim.log.levels.WARN)
	end
	local found = matching()
	if #found == 1 then
		return open(found[1], file)
	end
	local choices = #found > 1 and found or initiatives()
	local prompt = #found > 1 and "Initiative" or "No initiative mentions this checkout; pick one"
	vim.ui.select(choices, { prompt = prompt }, function(name)
		if name then
			open(name, file)
		end
	end)
end

vim.keymap.set("n", "<leader>ns", function()
	M.open("START-HERE.md")
end, { desc = "notes: this checkout's initiative START-HERE (open questions)" })

vim.keymap.set("n", "<leader>nt", function()
	M.open("Tasks.md")
end, { desc = "notes: this checkout's initiative Tasks" })

return M
