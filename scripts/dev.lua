vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*/codassist.nvim/lua/codassist/*.lua",
	callback = function()
		package.loaded.codassist = nil
		require("codassist").setup()
		print("codassist.nvim reloaded")
	end,
})
