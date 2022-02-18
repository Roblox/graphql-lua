-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/getOperationRootType.js

local GraphQLError = require(script.Parent.Parent.error.GraphQLError).GraphQLError

--[[*
--  * Extracts the root type of the operation from the schema.
--  *]]
local function getOperationRootType(schema, operation)
	if operation.operation == "query" then
		local queryType = schema:getQueryType()
		if not queryType then
			error(GraphQLError.new("Schema does not define the required query root type.", operation))
		end
		return queryType
	end

	if operation.operation == "mutation" then
		local mutationType = schema:getMutationType()
		if not mutationType then
			error(GraphQLError.new("Schema is not configured for mutations.", operation))
		end
		return mutationType
	end

	if operation.operation == "subscription" then
		local subscriptionType = schema:getSubscriptionType()
		if not subscriptionType then
			error(GraphQLError.new("Schema is not configured for subscriptions.", operation))
		end
		return subscriptionType
	end

	error(GraphQLError.new("Can only have query, mutation and subscription operations.", operation))
end

return {
	getOperationRootType = getOperationRootType,
}
