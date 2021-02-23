-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/promiseForObject.js
local jsutils = script.Parent
local graphql = jsutils.Parent
local Packages = graphql.Parent.Packages
local Promise = require(Packages.Promise)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

local ObjMapModule = require(script.Parent.ObjMap)
type ObjMap<T> = ObjMapModule.ObjMap<T>

local function promiseForObject(object: ObjMap<any>)
	local keys = Object.keys(object)
	local valuesAndPromises = Array.map(keys, function(name)
		-- deviation: Promise.all accepts only promises, so wrap
		-- each value in a resolved promise
		local value = object[name]
		if Promise.is(value) then
			return value
		end
		return Promise.resolve(value)
	end)

	return Promise.all(valuesAndPromises):andThen(function(values)
		return Array.reduce(values, function(resolvedObject, value, i_)
			-- ROBLOX FIXME: i_ is currently 0-based so we add 1 to account for that
			local i = i_ + 1
			resolvedObject[keys[i]] = value
			return resolvedObject
		end, {})
	end)
end

return {
	promiseForObject = promiseForObject,
}
