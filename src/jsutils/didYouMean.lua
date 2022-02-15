-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/didYouMean.js
local jsutils = script.Parent
local srcWorkspace = jsutils.Parent
local Packages = srcWorkspace.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>

local MAX_SUGGESTIONS = 5

--[[
 * Given [ A, B, C ] return ' Did you mean A, B, or C?'.
 ]]
local function didYouMean(firstArg: string, secondArg: Array<string>): string
	local subMessage
	-- ROBLOX TODO? some weird switcheroos here that make type analysis hard to figure
	local suggestionsArg: any = firstArg
	if typeof(firstArg) == "string" then
		subMessage = firstArg
		suggestionsArg = secondArg
	end

	local message = " Did you mean "
	if subMessage then
		message = message .. (subMessage .. " ")
	end

	local suggestions = {}
	for i = 1, #suggestionsArg do
		suggestions[i] = ("%q"):format(suggestionsArg[i])
	end

	local suggestionsLength = #suggestions
	if suggestionsLength == 0 then
		return ""
	elseif suggestionsLength == 1 then
		return message .. suggestions[1] .. "?"
	elseif suggestionsLength == 2 then
		return message .. suggestions[1] .. " or " .. suggestions[2] .. "?";
	end

	local selected = {}
	table.move(suggestions, 1, MAX_SUGGESTIONS, 1, selected)
	local lastItem = table.remove(selected)

	return message .. table.concat(selected, ", ") .. ", or " .. tostring(lastItem) .. "?"
end

return {
	didYouMean = didYouMean
}
