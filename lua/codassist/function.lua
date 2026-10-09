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
	if type:match("call") or type:match("index") then
		return false
	end
	return type:match("function") or type:match("method") or type == "lambda"
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

---@param node TSNode
local function find_previous_call(node)
	if node:type():match("call") then
		return node
	end
	local previous = node:prev_named_sibling()
	if previous ~= nil then
		local call = find_previous_call(previous)
		if call ~= nil then
			return call
		end
	end
	local parent = node:parent()
	if parent ~= nil then
		local call = find_previous_call(parent)
		if call ~= nil then
			return call
		end
	end
	return nil
end

-- TODO: refactor the whole file
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
			local previous_call = find_previous_call(surrounding_function)
			if previous_call ~= nil then
				local call_from_line, call_from_col, call_to_line, call_to_col = previous_call:range()
				local call_name = previous_call:field("name")[1] or previous_call:field("function")[1]
				local call_name_text = vim.treesitter.get_node_text(call_name, 0)
				vim.notify(
					call_name_text
						.. " ("
						.. previous_call:type()
						.. ") from="
						.. call_from_line
						.. ":"
						.. call_from_col
						.. " to="
						.. call_to_line
						.. ":"
						.. call_to_col,
					vim.log.levels.INFO,
					{ title = "Previous call" }
				)
				if
					call_from_line > symbol.range.start.line
					or (call_from_line == symbol.range.start.line and call_from_col > symbol.range.start.character)
				then
					vim.notify("Previous call is best!!!", vim.log.levels.INFO, { title = "Function name" })
				else
					local function_name = surrounding_function:field("name")[1]
					local function_name_text = ""
					if function_name ~= nil then
						function_name_text = vim.treesitter.get_node_text(function_name, 0)
					end
					vim.notify(
						"Comparing function_name_text="
							.. function_name_text
							.. " symbol.name="
							.. symbol.name
							.. " call_name_text="
							.. call_name_text,
						vim.log.levels.INFO,
						{ title = "Function name" }
					)
					if symbol.name ~= function_name_text and symbol.name == call_name_text then
						vim.notify("Previous call is perfectly best", vim.log.levels.INFO, { title = "Function name" })
					end
				end
			end
		end
	)
end

return M
