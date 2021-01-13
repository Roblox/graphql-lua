-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/blockString.js

local language = script.Parent
local src = language.Parent

local PolyArray = require(script.Parent.Parent.Parent.Packages.LuauPolyfill).Array

local slice = require(src.luaUtils.slice)
local sliceString = slice.sliceString
local Array = require(src.luaUtils.Array)
local charCodeAt = require(src.luaUtils.charCodeAt)
local String = require(src.luaUtils.String)

-- deviation: pre-declare functions
local getBlockStringIndentation
local dedentBlockStringValue
local printBlockString

function dedentBlockStringValue(rawString)
	-- Expand a block string's raw value into independent lines.
	local lines = String.split(rawString, { "\r\n", "\n", "\r" })

	-- Remove common indentation from all lines but first.
	local commonIndent = getBlockStringIndentation(rawString)

	if commonIndent ~= 0 then
		for i = 2, #lines do
			lines[i] = sliceString(lines[i], commonIndent + 1)
		end
	end

	-- Remove leading and trailing blank lines.
	local startLine = 0
	while startLine < #lines and isBlank(lines[startLine + 1]) do
		startLine = startLine + 1
	end

	-- Return a string of the lines joined with U+000A.
	local endLine = #lines
	while endLine > startLine and isBlank(lines[endLine - 1 + 1]) do
		endLine = endLine - 1
	end

	-- Return a string of the lines joined with U+000A.
	return Array.join(PolyArray.slice(lines, startLine + 1, endLine + 1), "\n")
end

function isBlank(str)
	for i = 1, #str do
		local charAtIndex = string.sub(str, i, i)
		if charAtIndex ~= " " and charAtIndex ~= "\t" then
			return false
		end
	end

	return true
end

function getBlockStringIndentation(value)
	local isFirstLine = true
	local isEmptyLine = true
	local indent = 0
	local commonIndent = nil

	local i = 1
	local valueLen = string.len(value)
	while i <= valueLen do
		local charAtIndex = charCodeAt(value, i)
		if charAtIndex == 13 then -- \r
			if charCodeAt(value, i + 1) == 10 then
				i = i + 1 -- skip \r\n as one symbol
			end
			-- falls through
		end
		if charAtIndex == 10 then -- \n
			isFirstLine = false
			isEmptyLine = true
			indent = 0
		elseif charAtIndex == 9 or charAtIndex == 32 then -- \t or <space>
			indent += 1
		else
			if isEmptyLine and isFirstLine ~= true and (commonIndent == nil or indent < commonIndent) then
				commonIndent = indent
			end

			isEmptyLine = false
		end

		i += 1
	end

	return commonIndent and commonIndent or 0
end

function printBlockString(value, _indentation, preferMultipleLines)
	local indentation = _indentation or ""
	local isSingleLine = string.find(value, "\n") == nil
	local hasLeadingSpace = string.sub(value, 1, 1) == " " or string.sub(value, 1, 1) == "\t"
	local hasTrailingQuote = string.sub(value, #value, #value) == "\""
	local hasTrailingSlash = string.sub(value, #value, #value) == "\\"
	local printAsMultipleLines = isSingleLine ~= true or hasTrailingQuote or hasTrailingSlash or preferMultipleLines

	local result = ""
	-- Format a multi-line block quote to account for leading space.
	if printAsMultipleLines and (isSingleLine and hasLeadingSpace) ~= true then
		result = result .. "\n" .. indentation
	end
	result = result .. (indentation ~= "" and string.gsub(value, "\n", "\n" .. indentation) or value)
	if printAsMultipleLines then
		result = result .. "\n"
	end
	return "\"\"\"" .. string.gsub(result, "\"\"\"", "\\\"\"\"") .. "\"\"\""
end

return {
	getBlockStringIndentation = getBlockStringIndentation,
	dedentBlockStringValue = dedentBlockStringValue,
	printBlockString = printBlockString,
}
