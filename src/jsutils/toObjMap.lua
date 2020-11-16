return function(obj)
	local map = {}
	for key, value in pairs(obj) do
		map[key] = value
	end
	return map
end
