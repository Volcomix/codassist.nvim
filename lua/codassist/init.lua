local M = {}

local ns = vim.api.nvim_create_namespace("codassist")

local function build_context(row, col)
	row = row - 1

	local prefix_lines = vim.api.nvim_buf_get_text(0, 0, 0, row, col, {})

	local line_count = vim.api.nvim_buf_line_count(0) - 1
	local suffix_lines = vim.api.nvim_buf_get_text(0, row, col, line_count, -1, {})

	return {
		prefix = table.concat(prefix_lines, "\n"),
		suffix = table.concat(suffix_lines, "\n"),
	}
end

local function build_body(context)
	return vim.json.encode({
		model = "gemma4",
		prompt = "<|fim_prefix|>" .. context.prefix .. "<|fim_suffix|>" .. context.suffix .. "<|fim_middle|>",
		stream = false,
		think = false,
		keep_alive = "60m",
		options = {
			temperature = 1.0,
			top_p = 0.95,
			top_k = 64,
			num_predict = 128,
		},
	})
end

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

local function insert_completion(lines, row, col)
	-- Use a new undo block for the inserted response
	-- https://neovim.io/doc/user/undo/#undo-break
	vim.opt_global.undolevels = vim.opt_global.undolevels

	vim.api.nvim_put(lines, "", false, true)

	local highlight_end = calculate_end(lines, row, col)
	show_highlight(row, col, highlight_end.row, highlight_end.col)
end

local function handle_output(out, row, col)
	local response = vim.json.decode(out.stdout).response
	local lines = vim.split(response, "\n")

	vim.schedule(function()
		insert_completion(lines, row, col)
	end)
end

local function autocomplete()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local context = build_context(row, col)
	local body = build_body(context)

	vim.system({ "curl", "http://localhost:11434/api/generate", "-d", body }, function(out)
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
