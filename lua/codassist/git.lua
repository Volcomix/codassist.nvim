local M = {}

local system_prompt = [[
Write a git commit message. The message must be short and fit on a single line, without any conventional prefix.
]]

---@param diff string?
local function build_body(diff)
	return vim.json.encode({
		messages = {
			{ role = "system", content = system_prompt },
			{ role = "user", content = diff },
		},
		temperature = 1.0,
		top_p = 0.95,
		top_k = 64,
		chat_template_kwargs = {
			enable_thinking = false,
		},
	})
end

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

---@param out vim.SystemCompleted
local function handle_completion_output(out)
	---@type string
	local message = vim.json.decode(out.stdout).choices[1].message.content
	vim.schedule(function()
		set_commit_message(message)
	end)
end

---@param out vim.SystemCompleted
local function handle_diff_output(out)
	local diff = out.stdout
	local body = build_body(diff)
	vim.system({ "curl", "http://localhost:8080/v1/chat/completions", "-d", body }, handle_completion_output)
end

function M.generate_commit_message()
	vim.system({ "git", "diff", "--cached" }, handle_diff_output)
end

return M
