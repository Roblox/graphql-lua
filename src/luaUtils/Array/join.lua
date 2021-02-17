type Array<T> = { [number]: T }
local Array = require(script.Parent.Parent.Parent.Parent.Packages.LuauPolyfill).Array
return function(arr_: Array<any>, separator: string?)
	-- JS does tostring conversion implicitely but in Lua we need to do that explicitely
	local arr = Array.map(arr_, function(item)
		return tostring(item)
	end)
	return table.concat(arr, separator or ",")
end
