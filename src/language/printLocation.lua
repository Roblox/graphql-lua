-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/printLocation.js
--!nolint LocalUnused
--!nolint FunctionUnused

local language = script.Parent
local src = language.Parent
local root = src.Parent

local getLocation = language.location
local Packages = root.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array

local function whitespace(len: number): string
	return Array(len + 1).join(" ")
end

local function leftPad(len: number, str: string): string
	return whitespace(len - str.length) .. str
end

local function printPrefixedLines(lines): string
	local existingLines = Array.filter(lines, function(prev)
		local _ = prev[1]
		local line = prev[2]
		return line ~= nil
	end)

	-- local padLen = max.max(existingLines.map(([prefix]) => prefix.length));
	local padLen = math.max(Array.map(existingLines, function(val)
		local prefix = val[1]
		return prefix:len()
	end))

	return Array.map(existingLines, function(val)
		local prefix = val[1]
		local line = val[2]
		return leftPad(padLen, prefix) .. line and "|" .. line or "|"
	end).join("\n")
end

local function printSourceLocation(source, sourceLocation)
	local firstLineColumnOffset = source.locationOffset.column - 1
	local body = whitespace(firstLineColumnOffset) + source.body

	local lineIndex = sourceLocation.line - 1
	local lineOffset = source.locationOffset.line - 1
	local lineNum = sourceLocation.line + lineOffset

	local columnOffset = sourceLocation.line == 1 and firstLineColumnOffset or 0
	local columnNum = sourceLocation.column + columnOffset
	local locationStr = source.name .. ":" .. lineNum .. ":" .. columnNum .. "\n"

	-- local lines = body.split(/\r\n|[\n\r]/g);
	-- local locationLine = lines[lineIndex];
end

local printLocation = function(location)
	return printSourceLocation(location.source, getLocation(location.source, location.start))
end

return {
	printSourceLocation = printSourceLocation,
	printLocation = printLocation,
}
