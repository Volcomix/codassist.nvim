local Provider = require("codassist.provider")

local M = {}

local system_prompt = [[
Write a short, single-line git commit message. Do not use a conventional prefix.
]]

---@param lines string[]
local function find_comment_start(lines)
	for i, line in ipairs(lines) do
		if line:match("^%s*#") then
			return i - 1
		end
	end
	return #lines
end

---@param message string
local function set_commit_message(message)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local comment_start = find_comment_start(lines)
	vim.api.nvim_buf_set_lines(0, 0, comment_start, false, vim.split(message, "\n"))
end

---@param result codassist.GenerateResult
local function handle_result(result)
	if result.error then
		vim.notify(result.error, vim.log.levels.ERROR, { title = "Failed to generate commit message" })
		return
	end
	vim.schedule(function()
		set_commit_message(result.text)
	end)
end

function M.generate_commit_message()
	vim.system({ "git", "diff", "--cached" }, function(out)
		Provider.generate(system_prompt, out.stdout, handle_result)
	end)
end

return M
