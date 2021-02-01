-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/printPathArray.js
type Array<T> = { [number]: T }

--[[
 * Build a string describing the path.
 ]]
local function printPathArray(
	path: Array<string | number>
): string
	local keys = {}
	for i = 1, #path do
		local key = path[i]
		keys[i] = typeof(key) == "number" and
			"[" .. tostring(key) .. "]" or
			"." .. key
	end
	return table.concat(keys, "")
end

return {
	printPathArray = printPathArray
}