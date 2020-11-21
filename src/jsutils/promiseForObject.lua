-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/promiseForObject.js
local jsutils = script.Parent
local graphql = jsutils.Parent
local Packages = graphql.Parent.Packages
local Promise = require(Packages.Promise)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

return function(object)
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
		return Array.reduce(
			values,
			function(resolvedObject, value, i)
				resolvedObject[keys[i]] = value
				return resolvedObject
			end,
			{}
		)
	end)
end
