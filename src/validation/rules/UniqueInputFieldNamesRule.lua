-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/validation/rules/UniqueInputFieldNamesRule.js

local root = script.Parent.Parent.Parent
local GraphQLError = require(root.error.GraphQLError).GraphQLError

local exports = {}

-- /**
--  * Unique input field names
--  *
--  * A GraphQL input object value is only valid if all supplied fields are
--  * uniquely named.
--  */
exports.UniqueInputFieldNamesRule = function(context)
	local knownNameStack = {}
	local knownNames: any = {}

	return {
		ObjectValue = {
			enter = function()
				table.insert(knownNameStack, knownNames)
				knownNames = {}
			end,
			leave = function()
				knownNames = table.remove(knownNameStack)
			end,
		},
		ObjectField = function(_self, node)
			local fieldName = node.name.value
			if knownNames[fieldName] then
				context:reportError(
					GraphQLError.new(
						('There can be only one input field named "%s".'):format(fieldName),
						{knownNames[fieldName], node.name}
					)
				)
			else
				knownNames[fieldName] = node.name
			end
		end,
	}
end

return exports
