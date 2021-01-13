local stringFindOr = require(script.Parent.Parent.stringFindOr)
local slice = require(script.Parent.Parent.slice)

return function(str: string, _patterns: string | Array<string>)
	local patterns: Array<string> = type(_patterns) == "string" and { _patterns } or _patterns
	local init = 1
	local result = {}
	repeat
		local match = stringFindOr(str, patterns, init)
		if match ~= nil then
			table.insert(result, slice.sliceString(str, init, match.index))
			init = match.index + #match.match
		else
			table.insert(result, slice.sliceString(str, init))
		end
	until match == nil or init > #str
	return result
end
