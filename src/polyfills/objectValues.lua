local graphql = script.Parent.Parent
local Packages = graphql.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)

return {
	objectValues = LuauPolyfill.Object.values,
}
