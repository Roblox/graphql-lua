local arrayContains = require(script.Parent.Parent.luaUtils.arrayContains)
local inspect = require(script.Parent.inspect).inspect

local function toArrayContains(tbl, item)
	local success = arrayContains(tbl, item)

	local message = ""
	if not success then
		-- TODO: find way to pretty print variables into output and expect it
		message = "recieved tbl: " .. inspect(item) .. " expected item to be in table: " .. inspect(tbl)
		message = "item not found in tbl"
	end

	return {
		pass = success,
		message = message,
	}
end

return toArrayContains
