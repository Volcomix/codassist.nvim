local M = {}

---@param system_prompt string
---@param user_prompt string
local function build_body(system_prompt, user_prompt)
	return vim.json.encode({
		model = "openai/gpt-oss-20b",
		messages = {
			{ role = "system", content = system_prompt },
			{ role = "user", content = user_prompt },
		},
		reasoning_effort = "low",
	})
end

---@param out vim.SystemCompleted
---@param on_complete fun(result: codassist.GenerateResult)
local function handle_output(out, on_complete)
	if out.code == 0 then
		on_complete({ text = vim.json.decode(out.stdout).choices[1].message.content })
	else
		on_complete({ error = out.stderr })
	end
end

---@param system_prompt string
---@param user_prompt string
---@param on_complete fun(result: codassist.GenerateResult)
function M.generate(system_prompt, user_prompt, on_complete)
	local body = build_body(system_prompt, user_prompt)
	vim.system({
		"curl",
		"https://api.groq.com/openai/v1/chat/completions",
		"-H",
		"Authorization: Bearer " .. os.getenv("GROQ_API_KEY"),
		"-d",
		body,
	}, function(out)
		handle_output(out, on_complete)
	end)
end

return M
