-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/promiseReduce.js
local jsutils = script.Parent
local graphql = jsutils.Parent
local Packages = graphql.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local isPromise = require(jsutils.isPromise).isPromise

--[[
 * Similar to Array.prototype.reduce(), however the reducing callback may return
 * a Promise, in which case reduction will continue after each promise resolves.
 *
 * If the callback does not return a Promise, then this function will also not
 * return a Promise.
 ]]
local function promiseReduce(values: Array<any>, callback: (U, T) -> any, initialValue: any)
	return Array.reduce(
		values,
		function(previous, value)
			if isPromise(previous) then
				return previous:andThen(function(resolved)
					return callback(resolved, value)
				end)
			end
			return callback(previous, value)
		end,
		initialValue
	)
end

return {
	promiseReduce = promiseReduce,
}
