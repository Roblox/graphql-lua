local devPrint = require(script.Parent.devPrint)
local deepContains = require(script.Parent.Parent.luaUtils.deepContains)


local function toObjectContain(a, b)
	local success = deepContains(a, b)

	local message = ""
	if not success then
		-- TODO: find way to pretty print variables into output and expect it
		message = "recieved tbl: " .. devPrint(b) .. " expected item to be in table: " .. devPrint(a)
		message = "item not found in tbl"
	end

	return {
		pass = success,
		message = message,
	}
end

return toObjectContain
