type Array<T> = { [number]: T }
local findOr = require(script.Parent.findOr)
local slice = require(script.Parent.slice)

return function(str: string, _patterns: string | Array<string>)
	local patterns: string | Array<string>
	if typeof(_patterns) == "string" then
		patterns = { _patterns }
	else
		patterns = _patterns
	end
	local init = 1
	local result = {}
	local lastMatch
	repeat
		local match = findOr(str, patterns, init)
		if match ~= nil then
			table.insert(result, slice(str, init, match.index))
			init = match.index + utf8.len(match.match)
		else
			table.insert(result, slice(str, init))
		end
		if match ~= nil then
			lastMatch = match
		end
	until match == nil or init > utf8.len(str)
	local strLen = utf8.len(str)
	if lastMatch ~= nil and lastMatch.index + utf8.len(lastMatch.match) == strLen + 1 then
		table.insert(result, "")
	end
	return result
end
