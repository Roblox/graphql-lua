-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/isPromise.js
local jsutils = script.Parent
local graphql = jsutils.Parent
local Packages = graphql.Parent.Packages
local Promise = require(Packages.Promise)

--[[
 * Returns true if the value acts like a Promise, i.e. has a "then" function,
 * otherwise returns false.
 ]]
return function(value)
	-- deviation: use the function provided by the Promise library
	return Promise.is(value)
end
