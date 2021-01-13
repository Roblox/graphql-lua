-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/dedent.js

local testUtilsWorkspace = script.Parent
local srcWorkspace = testUtilsWorkspace.Parent
local rootWorkspace = srcWorkspace.Parent
local PackagesWorkspace = rootWorkspace.Packages

local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Array = LuauPolyfill.Array
local String = require(srcWorkspace.luaUtils.String)

function dedent(strings: Array<string> | string, ...): string
	local values: Array<string> = { ... }

	local str = ""

	if Array.isArray(strings) then
		for i = 1, #strings do
			str ..= strings[i]
			if i <= #values then
				local value = values[i]

				str ..= value
			end
		end
	else
		str = strings
	end

	local trimmedStr = removeTrailingSpacesAndTabs(removeLeadingNewLines(str))
	local indent = ""
	for i = 1, string.len(trimmedStr) do
		local char = string.sub(trimmedStr, i, i)
		if char ~= " " and char ~= "\t" then
			break
		end
		indent ..= char
	end

	return removeCommonIndent(trimmedStr, indent)
end

function removeLeadingNewLines(str: string): string
	local leadingNewLinesMatch = String.findOr(str, { "\n*" })

	if leadingNewLinesMatch ~= nil and leadingNewLinesMatch.index == 1 then
		str = string.sub(str, string.len(leadingNewLinesMatch.match) + 1)
	end
	return str
end

function removeTrailingSpacesAndTabs(str: string): string
	local match
	local lastMatch
	local init = 1
	repeat
		match = String.findOr(str, { " +", "\t+" }, init)

		if match ~= nil then
			if lastMatch ~= nil and lastMatch.index + string.len(lastMatch.match) == match.index then
				lastMatch = {
					index = lastMatch.index,
					match = lastMatch.match .. match.match,
				}
			else
				lastMatch = match
			end
			init = match.index + string.len(match.match)
		end
	until match == nil or init > string.len(str)
	if lastMatch ~= nil and lastMatch.index + string.len(lastMatch.match) == string.len(str) + 1 then
		return string.sub(str, 1, lastMatch.index - 1)
	end
	return str
end

function removeCommonIndent(str: string, commonIndent: string): string
	local trimmedStr = string.gsub(str, commonIndent, "", 1)
	trimmedStr = string.gsub(trimmedStr, "\n" .. commonIndent, "\n")
	return trimmedStr
end

return dedent