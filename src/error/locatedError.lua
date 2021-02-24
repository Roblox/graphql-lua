-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/error/locatedError.js

type Array<T> = { [number]: T }

-- directory
local errorWorkspace = script.Parent
local srcWorkspace = errorWorkspace.Parent
local rootWorkspace = srcWorkspace.Parent
local Packages = rootWorkspace.Packages
-- require
local LuauPolyfill = require(Packages.LuauPolyfill)
local GraphQLError = require(errorWorkspace.GraphQLError).GraphQLError

local Array = LuauPolyfill.Array
local instanceOf = require(srcWorkspace.jsutils.instanceOf)
local inspect = require(srcWorkspace.jsutils.inspect).inspect
local Error = require(srcWorkspace.luaUtils.Error)

local function locatedError(
	rawOriginalError,
	nodes,
	path: Array<string | number>
)
	-- Sometimes a non-error is thrown, wrap it as an Error instance to ensure a consistent Error interface.
	local originalError
	if instanceOf(rawOriginalError, Error) then
		originalError = rawOriginalError
	elseif typeof(rawOriginalError) == "table" and typeof(rawOriginalError.error) == "string" then
		-- ROBLOX deviation: special case for errors thrown via 'error("error message")'
		originalError = Error.new("Unexpected error value: " .. inspect(rawOriginalError.error))
	else
		originalError = Error.new("Unexpected error value: " .. inspect(rawOriginalError))
	end

	-- Note: this uses a brand-check to support GraphQL errors originating from other contexts.
	if Array.isArray(originalError.path) then
		return originalError
	end

	local output = GraphQLError.new(
		originalError.message,
		originalError.nodes or nodes,
		originalError.source,
		originalError.positions,
		path,
		originalError
	)

	return output
end

return {
	locatedError = locatedError,
}
