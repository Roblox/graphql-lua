-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/error/syntaxError.js

local error = script.Parent
local GraphQLError = require(error.GraphQLError).GraphQLError

-- /**
--  * Produces a GraphQLError representing a syntax error, containing useful
--  * descriptive information about the syntax error's position in the source.
--  */
local function syntaxError(source, position: number, description: string)
	return GraphQLError.new("Syntax Error: " .. description, nil, source, { position })
end

return {
	syntaxError = syntaxError
}
