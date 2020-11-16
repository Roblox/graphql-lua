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
