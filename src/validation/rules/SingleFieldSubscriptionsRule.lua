-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/validation/rules/SingleFieldSubscriptionsRule.js

local root = script.Parent.Parent.Parent
local GraphQLError = require(root.error.GraphQLError).GraphQLError
local PackagesWorkspace = root.Parent.Packages
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Array = LuauPolyfill.Array

local exports = {}

-- /**
--  * Subscriptions must only include one field.
--  *
--  * A GraphQL subscription is valid only if it contains a single root field.
--  */
exports.SingleFieldSubscriptionsRule = function(context)
	return {
		OperationDefinition = function(_self, node)
			if node.operation == "subscription" then
				if #node.selectionSet.selections ~= 1 then
					context:reportError(
						GraphQLError.new(
							node.name
								and ('Subscription "%s" must select only one top level field.')
									:format(node.name.value)
								or "Anonymous Subscription must select only one top level field.",
							Array.slice(node.selectionSet.selections, 1)
						)
					)
				end
			end
		end,
	}
end

return exports
