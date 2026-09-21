local M = {}

local ns = vim.api.nvim_create_namespace("codassist")

local function clear_highlight()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function autocomplete()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1

	local prefix_lines = vim.api.nvim_buf_get_text(0, 0, 0, row, col, {})
	local prefix = table.concat(prefix_lines, "\n")

	local line_count = vim.api.nvim_buf_line_count(0) - 1
	local suffix_lines = vim.api.nvim_buf_get_text(0, row, col, line_count, -1, {})
	local suffix = table.concat(suffix_lines, "\n")

	local body = vim.json.encode({
		model = "gemma4",
		prompt = "<|fim_prefix|>" .. prefix .. "<|fim_suffix|>" .. suffix .. "<|fim_middle|>",
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

	vim.system({ "curl", "http://localhost:11434/api/generate", "-d", body }, function(out)
		local response = vim.json.decode(out.stdout).response
		local response_lines = vim.split(response, "\n")

		local end_row = row + #response_lines - 1
		local end_col

		if #response_lines == 1 then
			end_col = col + #response_lines[1]
		else
			end_col = #response_lines[#response_lines]
		end

		vim.schedule(function()
			-- Use a new undo block for the inserted response
			-- https://neovim.io/doc/user/undo/#undo-break
			vim.opt_global.undolevels = vim.opt_global.undolevels

			vim.api.nvim_put(response_lines, "", false, true)

			vim.api.nvim_buf_set_extmark(0, ns, row, col, {
				end_row = end_row,
				end_col = end_col,
				hl_group = "DiffAdd",
			})
		end)
	end)
end

function M.setup()
	vim.api.nvim_create_autocmd("InsertCharPre", { callback = clear_highlight })
	vim.api.nvim_create_autocmd("InsertLeave", { callback = clear_highlight })
	vim.keymap.set("i", "<M-Space>", autocomplete)
	vim.keymap.set("i", " ", autocomplete)
end

return M
