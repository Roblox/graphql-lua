local arrayContains = require(script.Parent.Parent.luaUtils.arrayContains)
local inspect = require(script.Parent.inspect).inspect

local function toArrayContains(tbl, item, looseEquals)
	local success = arrayContains(tbl, item, looseEquals)

	local message = ""
	if not success then
		-- TODO: find way to pretty print variables into output and expect it
		message = "received tbl: " .. inspect(item) .. " expected item to be in table: " .. inspect(tbl)
	end

	return {
		pass = success,
		message = message,
	}
end

return toArrayContains
