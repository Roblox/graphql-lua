-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/didYouMean.js
local MAX_SUGGESTIONS = 5

--[[
 * Given [ A, B, C ] return ' Did you mean A, B, or C?'.
 ]]
local function didYouMean(firstArg, secondArg)
	local subMessage = nil
	local suggestionsArg = firstArg
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

	return message .. table.concat(selected, ", ") .. ", or " .. lastItem .. "?"
end

return didYouMean
