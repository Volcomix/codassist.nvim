local M = {}

function M.setup()
	vim.keymap.set("i", "<M-Space>", function()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		print("row = " .. row .. ", col = " .. col)

		local prefix_lines = vim.api.nvim_buf_get_text(0, 0, 0, row, col, {})
		local prefix = table.concat(prefix_lines, "\n")
		print("prefix ---\n" .. prefix .. "|||")

		local line_count = vim.api.nvim_buf_line_count(0) - 1
		local suffix_lines = vim.api.nvim_buf_get_text(0, row, col, line_count, -1, {})
		local suffix = table.concat(suffix_lines, "\n")
		print("suffix ---\n" .. suffix .. "|||")
	end)
end

return M
