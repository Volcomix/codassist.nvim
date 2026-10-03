---@class codassist.GenerateResult
---@field text string?
---@field error string?

if vim.fn.has("mac") == 1 then
	return require("codassist.provider.mlx")
elseif vim.fn.has("linux") == 1 then
	-- TODO: handle linux with ollama
elseif vim.fn.has("termux") == 1 then
	-- TODO: handle termux with groq
end
