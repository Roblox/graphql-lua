-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/error/index.js

local graphQLErrorImport = require(script.GraphQLError)

return {
	GraphQLError = graphQLErrorImport.GraphQLError,
	printError = graphQLErrorImport.printError,
	syntaxError = require(script.syntaxError).syntaxError,
	locatedError = require(script.locatedError).locatedError,
	formatError = require(script.formatError).formatError,
}
