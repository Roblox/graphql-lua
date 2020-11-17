-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/printPathArray.js
type Array<T> = { T }

--[[
 * Build a string describing the path.
 ]]
return function(path: Array<string | number>)
	local keys = {}
	for i = 1, #path do
		local key = path[i]
		keys[i] = typeof(key) == "number" and
			"[" .. tostring(key) .. "]" or
			"." .. key
	end
	table.concat(keys, "")
end
