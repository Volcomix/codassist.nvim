local M = {}

function M.setup()
	vim.keymap.set("i", "<M-Space>", function()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		print("row = " .. row .. ", col = " .. col)

		local prefix_lines = vim.api.nvim_buf_get_text(0, 0, 0, row - 1, col, {})
		local prefix = table.concat(prefix_lines, "\n")
		print("prefix ---\n" .. prefix .. "|||")
	end)
end

return M
