local srcWorkspace = script.Parent.Parent
local PromiseModule = require(srcWorkspace.luaUtils.Promise)
type Promise<T> = PromiseModule.Promise<T>
local schemaModule = require(srcWorkspace.type.schema)
type GraphQLSchema = schemaModule.GraphQLSchema
type DocumentNode = any
type GraphQLFieldResolver<T, U> = any
type ExecutionResult = any

export type SubscriptionArgs = {
    schema: GraphQLSchema,
    document: DocumentNode,
    rootValue: any?,
    contextValue: any?,
    variableValues: { [string]: any },
    operationName: string?,
    fieldResolver: GraphQLFieldResolver<any, any>?,
    subscribeFieldResolver: GraphQLFieldResolver<any, any>?
}

local function subscribe(
	args: SubscriptionArgs
  ): Promise<ExecutionResult>
  error("graphql-lua does not currently implement subscriptions")
end

local function createSourceEventStream(
	schema: GraphQLSchema,
	document: DocumentNode,
	rootValue: any?,
	contextValue: any?,
	variableValues: { [string]: any }?,
	operationName: string?,
	fieldResolver: GraphQLFieldResolver<any, any>?
  ): Promise<ExecutionResult>
  error("graphql-lua does not currently implement subscriptions")
end

return {
	subscribe = subscribe,
	createSourceEventStream = createSourceEventStream
}