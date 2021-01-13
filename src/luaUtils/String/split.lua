local findOr = require(script.Parent.findOr)
local slice = require(script.Parent.Parent.slice)

return function(str: string, _patterns: string | Array<string>)
	local patterns: Array<string> = type(_patterns) == "string" and { _patterns } or _patterns
	local init = 1
	local result = {}
	local lastMatch
	repeat
		local match = findOr(str, patterns, init)
		if match ~= nil then
			table.insert(result, slice.sliceString(str, init, match.index))
			init = match.index + #match.match
		else
			table.insert(result, slice.sliceString(str, init))
		end
		if match ~= nil then
			lastMatch = match
		end
	until match == nil or init > #str
	if lastMatch ~= nil and lastMatch.index + string.len(lastMatch.match) == string.len(str) + 1 then
		table.insert(result, "")
	end
	return result
end
