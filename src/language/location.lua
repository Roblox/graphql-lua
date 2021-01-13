-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/location.js
local src = script.Parent.Parent
local String = require(src.luaUtils.String)

local exports = {}

-- /**
--  * Takes a Source and a UTF-8 character offset, and returns the corresponding
--  * line and column as a SourceLocation.
--  */
exports.getLocation = function(source, position)
	local terms = { "\r\n", "\r", "\n" }
	local line = 1
	local column = position + 1
	local match = String.findOr(source.body, terms)
	while match ~= nil and match.index < position do
		line += 1
		column = position + 1 - match.index + string.len(match.match)
		match = String.findOr(source.body, terms)
	end

	return { line = line, column = column }
end

return exports
