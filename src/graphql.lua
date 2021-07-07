-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/graphql.js

local rootWorkspace = script.Parent

-- ROBLOX deviation: add polyfills
local Error = require(rootWorkspace.luaUtils.Error)
local Packages = rootWorkspace.Parent
local Promise = require(Packages.Promise)
local PromiseModule = require(rootWorkspace.luaUtils.Promise)
type Promise<T> = PromiseModule.Promise<T>
local PromiseOrValueModule = require(rootWorkspace.jsutils.PromiseOrValue)
type PromiseOrValue<T> = PromiseOrValueModule.PromiseOrValue<T>

local isPromise = require(rootWorkspace.jsutils.isPromise).isPromise

local sourceModule = require(rootWorkspace.language.source)
type Source = sourceModule.Source
local parse = require(rootWorkspace.language.parser).parse

local definitionModule = require(rootWorkspace.type.definition)
-- ROBLOX deviation: Luau doesn't currently support default type args, so add the third one here until it does
type GraphQLFieldResolver<T, V> = definitionModule.GraphQLFieldResolver<T, V, any>
type GraphQLTypeResolver<T, V> = definitionModule.GraphQLTypeResolver<T, V>
local schemaModule = require(rootWorkspace.type.schema)
type GraphQLSchema = schemaModule.GraphQLSchema
local validate = require(rootWorkspace.validation.validate).validate

local validateSchema = require(rootWorkspace.type.validate).validateSchema

local executeModule = require(rootWorkspace.execution.execute)
local execute = executeModule.execute
type ExecutionResult = executeModule.ExecutionResult

local exports = {}

--[[**
--  * This is the primary entry point function for fulfilling GraphQL operations
--  * by parsing, validating, and executing a GraphQL document along side a
--  * GraphQL schema.
--  *
--  * More sophisticated GraphQL servers, such as those which persist queries,
--  * may wish to separate the validation and execution phases to a static time
--  * tooling step, and a server runtime step.
--  *
--  * Accepts either an object with named arguments, or individual arguments:
--  *
--  * schema:
--  *    The GraphQL type system to use when validating and executing a query.
--  * source:
--  *    A GraphQL language formatted string representing the requested operation.
--  * rootValue:
--  *    The value provided as the first argument to resolver functions on the top
--  *    level type (e.g. the query object type).
--  * contextValue:
--  *    The context value is provided as an argument to resolver functions after
--  *    field arguments. It is used to pass shared information useful at any point
--  *    during executing this query, for example the currently logged in user and
--  *    connections to databases or other services.
--  * variableValues:
--  *    A mapping of variable name to runtime value to use for all variables
--  *    defined in the requestString.
--  * operationName:
--  *    The name of the operation to use if requestString contains multiple
--  *    possible operations. Can be omitted if requestString contains only
--  *    one operation.
--  * fieldResolver:
--  *    A resolver function to use when one is not provided by the schema.
--  *    If not provided, the default field resolver is used (which looks for a
--  *    value or method on the source value with the field's name).
--  * typeResolver:
--  *    A type resolver function to use when none is provided by the schema.
--  *    If not provided, the default type resolver is used (which looks for a
--  *    `__typename` field or alternatively calls the `isTypeOf` method).
--  *]]
export type GraphQLArgs = {
	schema: GraphQLSchema,
	source: string | Source,
	rootValue: any?,
	contextValue: any?,
	variableValues: { [string]: any }?,
	operationName: string?,
	fieldResolver: GraphQLFieldResolver<any, any>?,
	typeResolver: GraphQLTypeResolver<any, any>?,
}

-- ROBLOX deviation: pre-declare variables
local graphqlImpl

exports.graphql = function(args: GraphQLArgs): Promise<ExecutionResult>
	-- Always return a Promise for a consistent API.
	return Promise.new(function(resolve)
		return resolve(graphqlImpl(args))
	end)
end

--[[**
--  * The graphqlSync function also fulfills GraphQL operations by parsing,
--  * validating, and executing a GraphQL document along side a GraphQL schema.
--  * However, it guarantees to complete synchronously (or throw an error) assuming
--  * that all field resolvers are also synchronous.
--  *]]
exports.graphqlSync = function(args: GraphQLArgs): ExecutionResult
	local result = graphqlImpl(args)

	-- Assert that the execution was synchronous.
	if isPromise(result) then
		error(Error.new("GraphQL execution failed to complete synchronously."))
	end

	return result
end

function graphqlImpl(args: GraphQLArgs):PromiseOrValue<ExecutionResult>
	local schema = args.schema
	local source = args.source
	local rootValue = args.rootValue
	local contextValue = args.contextValue
	local variableValues = args.variableValues
	local operationName = args.operationName
	local fieldResolver = args.fieldResolver
	local typeResolver = args.typeResolver

	-- Validate Schema
	local schemaValidationErrors = validateSchema(schema)
	if #schemaValidationErrors > 0 then
		return { errors = schemaValidationErrors }
	end

	-- Parse
	local document
	local ok, syntaxError = pcall(function()
		document = parse(source)
	end)
	if not ok then
		return { errors = { syntaxError } }
	end

	-- Validate
	local validationErrors = validate(schema, document)
	if #validationErrors > 0 then
		return { errors = validationErrors }
	end

	-- Execute
	return execute({
		schema = schema,
		document = document,
		rootValue = rootValue,
		contextValue = contextValue,
		variableValues = variableValues,
		operationName = operationName,
		fieldResolver = fieldResolver,
		typeResolver = typeResolver,
	})
end

return exports
