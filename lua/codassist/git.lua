local M = {}

---@param out vim.SystemCompleted
local function handle_diff_output(out)
	local diff = out.stdout
	print("diff ---\n" .. diff .. "|||")
end

function M.generate_commit_message()
	vim.system({ "git", "diff", "--cached" }, handle_diff_output)
end

return M
