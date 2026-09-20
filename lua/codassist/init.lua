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
			print("response ---\n" .. response .. "|||")
			vim.schedule(function()
				vim.api.nvim_put(vim.split(response, "\n"), "", false, true)
			end)
		end)
	end)
end

return M
