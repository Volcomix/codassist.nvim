local M = {}

local ns = vim.api.nvim_create_namespace("codassist")

---@class codassist.Context
---@field prefix string
---@field suffix string

---@param row integer
---@param col integer
---@return codassist.Context
local function build_context(row, col)
	local prefix_lines = vim.api.nvim_buf_get_text(0, 0, 0, row, col, {})

	local line_count = vim.api.nvim_buf_line_count(0) - 1
	local suffix_lines = vim.api.nvim_buf_get_text(0, row, col, line_count, -1, {})

	return {
		prefix = table.concat(prefix_lines, "\n"),
		suffix = table.concat(suffix_lines, "\n"),
	}
end

local system_prompt = [[
You are an inline code completion engine.
The user provides source code containing exactly one <MISSING_CODE> marker.
Replace <MISSING_CODE> with the code that belongs there.
Return only the replacement code.
Do not repeat any surrounding code.
Do not output Markdown, code fences, explanations, or comments about the completion.
]]

local user_prompt_prefix = [[
Replace <MISSING_CODE> in the following source code.
Return only the code that should replace <MISSING_CODE>.

```
]]

local user_prompt_middle = "<MISSING_CODE>"

local user_prompt_suffix = [[

```
]]

---@param context codassist.Context
local function build_body(context)
	local user_prompt = user_prompt_prefix
		.. context.prefix
		.. user_prompt_middle
		.. context.suffix
		.. user_prompt_suffix

	return vim.json.encode({
		messages = {
			{ role = "system", content = system_prompt },
			{ role = "user", content = user_prompt },
		},
		max_tokens = 128,
		temperature = 0.0,
		top_p = 0.95,
		top_k = 64,
		chat_template_kwargs = {
			enable_thinking = false,
		},
	})
end

---@param lines string[]
---@param row integer
---@param col integer
local function calculate_end(lines, row, col)
	local end_col

	if #lines == 1 then
		end_col = col + #lines[1]
	else
		end_col = #lines[#lines]
	end

	return {
		row = row + #lines - 1,
		col = end_col,
	}
end

---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
local function show_highlight(start_row, start_col, end_row, end_col)
	vim.api.nvim_buf_set_extmark(0, ns, start_row, start_col, {
		end_row = end_row,
		end_col = end_col,
		hl_group = "DiffAdd",
	})
end

local function hide_highlight()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

---@param lines string[]
---@param row integer
---@param col integer
local function insert_completion(lines, row, col)
	-- Use a new undo block for the inserted response
	-- https://neovim.io/doc/user/undo/#undo-break
	vim.opt_global.undolevels = vim.opt_global.undolevels

	vim.api.nvim_put(lines, "", false, true)

	local highlight_end = calculate_end(lines, row, col)
	show_highlight(row, col, highlight_end.row, highlight_end.col)
end

---@param out vim.SystemCompleted
---@param row integer
---@param col integer
local function handle_output(out, row, col)
	local content = vim.json.decode(out.stdout).choices[1].message.content
	local lines = vim.split(content, "\n")

	vim.schedule(function()
		insert_completion(lines, row, col)
	end)
end

local function autocomplete()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1

	local context = build_context(row, col)
	local body = build_body(context)

	vim.system({ "curl", "http://localhost:8080/v1/chat/completions", "-d", body }, function(out)
		handle_output(out, row, col)
	end)
end

function M.setup()
	vim.api.nvim_create_autocmd("InsertCharPre", { callback = hide_highlight })
	vim.api.nvim_create_autocmd("InsertLeave", { callback = hide_highlight })
	vim.keymap.set("i", "<M-Space>", autocomplete)
	vim.keymap.set("i", " ", autocomplete)
end

return M
