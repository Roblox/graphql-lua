local function createSymbol(name)
	assert(typeof(name) == "string")
	local symbol = newproxy(true)
	getmetatable(symbol).__tostring = function()
		return ("Symbol(Symbol.%s)"):format(name)
	end
	return symbol
end

return {
	SYMBOL_ITERATOR = createSymbol("iterator"),
	SYMBOL_ASYNC_ITERATOR = createSymbol("asyncIterator"),
	SYMBOL_TO_STRING_TAG = createSymbol("toStringTag"),
}
