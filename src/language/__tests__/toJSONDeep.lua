-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/toJSONDeep.js

local srcWorkspace = script.Parent.Parent.Parent
local root = srcWorkspace.Parent

local isObjectLike = require(srcWorkspace.jsutils.isObjectLike)
local Array = require(root.Packages.LuauPolyfill).Array
-- /**
--  * Deeply transforms an arbitrary value to a JSON-safe value by calling toJSON
--  * on any nested value which defines it.
--  */
local function toJSONDeep(value)
	if not isObjectLike(value) then
		return value
	end

	if type(value.toJSON) == "function" then
		return value:toJSON()
	end

	if Array.isArray(value) then
		return Array.map(value, toJSONDeep)
	end

	local result = {}

	for prop, val in pairs(value) do
		result[prop] = toJSONDeep(val)
	end

	return result
end

return toJSONDeep
