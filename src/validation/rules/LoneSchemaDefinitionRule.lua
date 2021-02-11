-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/validation/rules/LoneSchemaDefinitionRule.js

local root = script.Parent.Parent.Parent
local GraphQLError = require(root.error.GraphQLError).GraphQLError

local exports = {}

-- /**
--  * Lone Schema definition
--  *
--  * A GraphQL document is only valid if it contains only one schema definition.
--  */
exports.LoneSchemaDefinitionRule = function(context)
	local oldSchema = context:getSchema()
	local alreadyDefined = nil
	if oldSchema then
		alreadyDefined = oldSchema.astNode
		if alreadyDefined == nil then
			alreadyDefined = oldSchema:getQueryType()
		end
		if alreadyDefined == nil then
			alreadyDefined = oldSchema:getMutationType()
		end
		if alreadyDefined == nil then
			alreadyDefined = oldSchema:getSubscriptionType()
		end
	end

	local schemaDefinitionsCount = 0
	return {
		SchemaDefinition = function(_self, node)
			if alreadyDefined then
				context:reportError(
					GraphQLError.new(
						"Cannot define a new schema within a schema extension.",
						node
					)
				)
				return
			end

			if schemaDefinitionsCount > 0 then
				context:reportError(
					GraphQLError.new(
						"Must provide only one schema definition.",
						node
					)
				)
			end
			schemaDefinitionsCount = schemaDefinitionsCount + 1
		end,
	}
end

return exports