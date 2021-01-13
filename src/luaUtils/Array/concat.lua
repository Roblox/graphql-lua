return function(...)
	local srcWorkspace = script.Parent.Parent.Parent
	local root = srcWorkspace.Parent
	local Array = require(root.Packages.LuauPolyfill).Array

	local arrs = { ... }
	local res = {}
	for i = 1, #arrs do
		local arr = arrs[i]
		if Array.isArray(arr) then
			for j = 1, #arr do
				table.insert(res, arr[j])
			end
		else
			table.insert(res, arr)
		end
	end
	return res
end
