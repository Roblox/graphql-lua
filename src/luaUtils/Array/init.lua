local root = script.Parent.Parent
local PackagesWorkspace = root.Parent.Packages
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

return Object.assign({}, Array, {
	concat = require(script.concat),
	includes = require(script.includes),
	join = require(script.join),
})
