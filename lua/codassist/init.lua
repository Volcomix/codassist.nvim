local wk = require("which-key")
local Function = require("codassist.function")
local Git = require("codassist.git")

local M = {}

local function setup_gitcommit()
	wk.add({ "<leader>ag", group = "git", buffer = 0 })
	vim.keymap.set("n", "<leader>agc", Git.generate_commit_message, { desc = "Commit message", buf = 0 })
end

function M.setup()
	wk.add({
		{ "<leader>a", group = "assist", icon = { icon = "󰢚", color = "orange" } },
		{ "<leader>af", group = "function", icon = { icon = "󰊕", color = "blue" } },
	})
	vim.keymap.set("n", "<leader>afb", Function.generate_body, { desc = "Function body" })
	vim.api.nvim_create_autocmd("FileType", { pattern = "gitcommit", callback = setup_gitcommit })
end

return M
