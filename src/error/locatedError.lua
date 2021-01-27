-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/error/locatedError.js

-- directory
local errorWorkspace = script.Parent
local srcWorkspace = errorWorkspace.Parent
local rootWorkspace = srcWorkspace.Parent
local Packages = rootWorkspace.Packages
-- require
local LuauPolyfill = require(Packages.LuauPolyfill)
local GraphQLError = require(errorWorkspace.GraphQLError).GraphQLError

local Array = LuauPolyfill.Array

local function locatedError(originalError, nodes, path)
	-- Note: this uses a brand-check to support GraphQL errors originating from other contexts.
	if Array.isArray(originalError.path) then
		return originalError
	end

	local output = GraphQLError.new(
		originalError.message,
		originalError.nodes or nil,
		originalError.source or nil,
		originalError.positions,
		path,
		originalError
	)

	return output
end

return {
	locatedError = locatedError,
}
