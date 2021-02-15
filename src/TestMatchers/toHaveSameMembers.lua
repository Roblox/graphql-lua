local arrayContains = require(script.Parent.Parent.luaUtils.arrayContains)
local inspect = require(script.Parent.inspect).inspect

local function toHaveSameMembers(arrA, arrB)

	local sameLength = #arrA == #arrB
	if not sameLength then
		return {
			pass = false,
			message = ("Received array length %s / expected length %s"):format(tostring(#arrA), tostring(#arrB)),
		}
	end

	for _, itemA in ipairs(arrA) do
		local foundItem = arrayContains(arrB, itemA)
		if not foundItem then
			return {
				pass = false,
				message = ("Expected item %s to be in Array %s"):format(inspect(itemA), inspect(arrB)),
			}
		end
	end

	return {
		pass = true,
		message = "",
	}
end

return toHaveSameMembers
