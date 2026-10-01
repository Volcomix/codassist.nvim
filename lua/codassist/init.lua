local wk = require("which-key")
local Completion = require("codassist.completion")
local Git = require("codassist.git")

local M = {}

local keymap_group = {
	"<leader>a",
	group = "assist",
	icon = { icon = "󰢚", color = "orange" },
	buffer = 0,
}

local function setup_gitcommit()
	wk.add({ keymap_group })

	vim.keymap.set("n", "<leader>ac", Git.generate_commit_message, {
		desc = "Generate commit message",
		buf = 0,
	})
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", { pattern = "gitcommit", callback = setup_gitcommit })
	vim.api.nvim_create_autocmd("InsertCharPre", { callback = Completion.clear })
	vim.api.nvim_create_autocmd("InsertLeave", { callback = Completion.clear })
	vim.keymap.set("i", "<M-Space>", Completion.generate, { desc = "Autocomplete" })
end

return M
