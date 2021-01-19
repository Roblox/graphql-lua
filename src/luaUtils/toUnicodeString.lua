local sliceString = require(script.Parent.slice).sliceString

-- used in lexer.printCharCode
return function(code)
	-- convert dex to hexadex
	local hex = string.format("%x", code)
	-- prepend 4 spaces
	local pre = "0000" .. hex
	-- take rightmost 4 characters
	local val = sliceString(pre, -3)
	-- then combine with "\\u${}"
	local out = "\"\\u" .. val .. "\""
	return out
end
