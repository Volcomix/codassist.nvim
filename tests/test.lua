local sloubi, prout = function()
	print("sloubi")
	vim.system("sloubi", function(out)
		print(out.stdout)
	end)
end

local testouille = {
	sloubi = function()
		print("sloubi")
	end,
}
