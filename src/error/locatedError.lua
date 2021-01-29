-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/error/locatedError.js

-- directory
local errorWorkspace = script.Parent
local srcWorkspace = errorWorkspace.Parent
local rootWorkspace = srcWorkspace.Parent
local Packages = rootWorkspace.Packages
-- require
local LuauPolyfill = require(Packages.LuauPolyfill)
local GraphQLError = require(errorWorkspace.GraphQLError).GraphQLError

local Array = LuauPolyfill.Array

local function locatedError(
	originalError,
	nodes,
	path: Array<string | number>): GraphQLError
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
