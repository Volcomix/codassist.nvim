local M = {}

local system_prompt = [[
You write concise Git change descriptions. Analyze the staged diff and produce exactly one concise sentence describing the actual change introduced by the diff.
Use imperative mood. Do not use a conventional-commit prefix such as feat:, fix:, chore:, refactor:, docs:, or test:.
Do not mention the diff itself. Do not include quotes, markdown, explanations, or a period at the end. Output only the sentence.
]]

local user_prompt_prefix = [[
Staged diff:

]]

---@param diff string?
local function build_body(diff)
	return vim.json.encode({
		messages = {
			{ role = "system", content = system_prompt },
			{ role = "user", content = user_prompt_prefix .. diff },
		},
		temperature = 0.0,
		top_p = 0.95,
		top_k = 64,
		chat_template_kwargs = {
			enable_thinking = false,
		},
	})
end

---@param out vim.SystemCompleted
local function handle_completion_output(out)
	local content = vim.json.decode(out.stdout).choices[1].message.content
	print("content ---\n" .. content .. "|||")
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
