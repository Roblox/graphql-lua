-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/isPromise.js
local jsutils = script.Parent
local invariant = require(jsutils.invariant)
local nodejsCustomInspectSymbol = require(jsutils.nodejsCustomInspectSymbol)

--[[
 * The `defineInspect()` function defines `inspect()` prototype method as alias of `toJSON`
 ]]
return function(classObject)
	local fn = classObject.toJSON
	invariant(typeof(fn) == "function")

	classObject.inspect = fn

	-- // See: 'https://github.com/graphql/graphql-js/issues/2317'
	if nodejsCustomInspectSymbol then
		classObject[nodejsCustomInspectSymbol] = fn
	end
end
