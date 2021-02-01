-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/error/formatError.js

local src = script.Parent.Parent
local devAssert = require(src.jsutils.devAssert).devAssert

local exports = {}

-- /**
-- * Given a GraphQLError, format it according to the rules described by the
-- * Response Format, Errors section of the GraphQL Specification.
-- */
exports.formatError = function(error_)

	devAssert(error_, "Received nil error.")

	local message = error_.message or "An unknown error occurred."
	local locations = error_.locations
	local path = error_.path
	local extensions = error_.extensions

	return extensions and {
		message = message,
		locations = locations,
		path = path,
		extensions = extensions,
	} or {
		message = message,
		locations = locations,
		path = path,
	}
end

return exports
