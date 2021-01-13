local deepEqual = require(script.Parent.deepEqual)

return function(tbl, item)
	-- see if item exists in table
	for _, value in ipairs(tbl) do
		if deepEqual(value, item) then
			return true
		end
	end

	return false
end
