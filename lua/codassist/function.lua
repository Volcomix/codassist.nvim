local M = {}

---@class codassist.Position
---@field line integer
---@field col integer

---@class codassist.Range
---@field from codassist.Position
---@field to codassist.Position

---@param node TSNode
local function is_function(node)
	local type = node:type()
	if type:match("call") then
		return false
	end
	return type:match("function") or type:match("method") or type:match("lambda")
end

local function find_surrounding_function()
	local node = vim.treesitter.get_node()
	while node ~= nil do
		if is_function(node) then
			return node
		end
		node = node:parent()
	end
	return nil
end

---@param symbols lsp.DocumentSymbol[]
---@param range codassist.Range
---@param surrounding boolean|nil
local function find_symbol(symbols, range, surrounding)
	-- TODO: replace surrounding with an opts parameter
	-- TODO: document or find another way than sorting symbols which comes from outside this function
	table.sort(symbols, function(a, b)
		return a.range.start.line > b.range.start.line
			or (a.range.start.line == b.range.start.line and a.range.start.character > b.range.start.character)
	end)
	for _, symbol in ipairs(symbols) do
		if symbol.children ~= nil then
			local surrounding_symbol = find_symbol(symbol.children, range, surrounding)
			if surrounding_symbol ~= nil then
				return surrounding_symbol
			end
		end
		if
			(
				symbol.range.start.line < range.from.line
				or (symbol.range.start.line == range.from.line and symbol.range.start.character <= range.from.col)
			)
			and (
				surrounding == false
				or symbol.range["end"].line > range.to.line
				or (symbol.range["end"].line == range.to.line and symbol.range["end"].character >= range.to.col)
			)
		then
			return symbol
		end
	end
	return nil
end

function M.generate_body()
	local surrounding_function = find_surrounding_function()
	if surrounding_function == nil then
		vim.notify("Not in a function", vim.log.levels.WARN, { title = "Can't generate function body" })
		return
	end
	local body = surrounding_function:field("body")[1]
	if body == nil then
		vim.notify("No function body", vim.log.levels.ERROR, { title = "Can't generate function body" })
		return
	end
	local from_line, from_col, to_line, to_col = body:range()
	---@type codassist.Range
	local range = { from = { line = from_line, col = from_col }, to = { line = to_line, col = to_col } }
	vim.notify(
		"from=" .. from_line .. ":" .. from_col .. " to=" .. to_line .. ":" .. to_col,
		vim.log.levels.INFO,
		{ title = "TSNode" }
	)
	vim.lsp.buf_request(
		0,
		"textDocument/documentSymbol",
		{ textDocument = vim.lsp.util.make_text_document_params() },
		---@param result lsp.DocumentSymbol[]
		function(err, result)
			if err then
				vim.notify(err.message, vim.log.levels.ERROR, { title = "Failed to retrieve document symbols" })
				return
			end
			local symbol = find_symbol(result, range)
			if symbol == nil then
				from_line, from_col, to_line, to_col = surrounding_function:range()
				range = { from = { line = from_line, col = from_col }, to = { line = to_line, col = to_col } }
				symbol = find_symbol(result, range, false)
			end
			if symbol == nil then
				vim.notify("Not in a named function", vim.log.levels.ERROR, { title = "Can't generate function body" })
				return
			end
			vim.notify(
				symbol.name
					.. " ("
					.. symbol.kind
					.. ") from="
					.. symbol.range.start.line
					.. ":"
					.. symbol.range.start.character
					.. " to="
					.. symbol.range["end"].line
					.. ":"
					.. symbol.range["end"].character
					.. " | from="
					.. symbol.selectionRange.start.line
					.. ":"
					.. symbol.selectionRange.start.character
					.. " to="
					.. symbol.selectionRange["end"].line
					.. ":"
					.. symbol.selectionRange["end"].character,
				vim.log.levels.INFO,
				{ title = "Document symbol" }
			)
			vim.notify(symbol.detail, vim.log.levels.INFO, { title = "Symbol details" })
		end
	)
end

return M
