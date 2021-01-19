-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/location.js
local src = script.Parent.Parent
local String = require(src.luaUtils.String)

-- /**
--  * Takes a Source and a UTF-8 character offset, and returns the corresponding
--  * line and column as a SourceLocation.
--  * ROBLOX deviation: position takes 1-based index
--  */
local function getLocation(source, position)
	local terms = { "\r\n", "\r", "\n" }
	local line = 1
	local column = position
	local match = String.findOr(source.body, terms)
	while match ~= nil and match.index < position do
		local init = match.index + string.len(match.match)
		line += 1
		column = position + 1 - init
		match = String.findOr(source.body, terms, init)
	end

	return { line = line, column = column }
end

return {
	getLocation = getLocation,
}
