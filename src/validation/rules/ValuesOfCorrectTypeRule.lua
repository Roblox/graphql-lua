-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/validation/rules/ValuesOfCorrectTypeRule.js

local root = script.Parent.Parent.Parent
local jsutils = root.jsutils
local instanceOf = require(jsutils.instanceOf)
local objectValues = require(root.polyfills.objectValues).objectValues
local keyMap = require(jsutils.keyMap).keyMap
local inspect = require(jsutils.inspect).inspect
local didYouMean = require(jsutils.didYouMean).didYouMean
local suggestionList = require(jsutils.suggestionList).suggestionList
local GraphQLError = require(root.error.GraphQLError).GraphQLError
local language = root.language
local print_ = require(language.printer).print
local definition = require(root.type.definition)
local isLeafType = definition.isLeafType
local isInputObjectType = definition.isInputObjectType
local isListType = definition.isListType
local isNonNullType = definition.isNonNullType
local isRequiredInputField = definition.isRequiredInputField
local getNullableType = definition.getNullableType
local getNamedType = definition.getNamedType
local PackagesWorkspace = root.Parent.Packages
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Object = LuauPolyfill.Object

local exports = {}

-- ROBLOX deviation: pre-declare function
local isValidValueNode

-- /**
--  * Value literals of correct type
--  *
--  * A GraphQL document is only valid if all value literals are of the type
--  * expected at their position.
--  */
exports.ValuesOfCorrectTypeRule = function(context)
	return {
		ListValue = function(_self, node)
			-- // Note: TypeInfo will traverse into a list's item type, so look to the
			-- // parent input type to check if it is a list.
			local type_ = getNullableType(context:getParentInputType())
			if not isListType(type_) then
				isValidValueNode(context, node)
				return false -- // Don't traverse further.
			end
			return
		end,
		ObjectValue = function(_self, node)
			local type_ = getNamedType(context:getInputType())
			if not isInputObjectType(type_) then
				isValidValueNode(context, node)
				return false -- // Don't traverse further.
			end
			-- // Ensure every required field exists.
			local fieldNodeMap = keyMap(node.fields, function(field)
				return field.name.value
			end)
			for _, fieldDef in ipairs(objectValues(type_:getFields()))do
				local fieldNode = fieldNodeMap[fieldDef.name]
				if not fieldNode and isRequiredInputField(fieldDef) then
					local typeStr = inspect(fieldDef.type)
					context:reportError(
						GraphQLError.new(
							('Field "%s.%s" of required type "%s" was not provided.'):format(
								type_.name,
								fieldDef.name,
								typeStr
							),
							node
						)
					)
				end
			end
			return
		end,
		ObjectField = function(_self, node)
			local parentType = getNamedType(context:getParentInputType())
			local fieldType = context:getInputType()
			if not fieldType and isInputObjectType(parentType) then
				local suggestions = suggestionList(
					node.name.value,
					Object.keys(parentType:getFields())
				)
				context:reportError(
					GraphQLError.new(
						('Field "%s" is not defined by type "%s".'):format(
							node.name.value,
							parentType.name
						) .. didYouMean(suggestions),
						node
					)
				)
			end
		end,
		NullValue = function(_self, node)
			local type_ = context:getInputType()
			if isNonNullType(type_) then
				context:reportError(
					GraphQLError.new(
						('Expected value of type "%s", found %s.'):format(
							inspect(type_),
							print_(node)
						),
						node
					)
				)
			end
		end,
		EnumValue = function(_self, node)
			return isValidValueNode(context, node)
		end,
		IntValue = function(_self, node)
			return isValidValueNode(context, node)
		end,
		FloatValue = function(_self, node)
			return isValidValueNode(context, node)
		end,
		StringValue = function(_self, node)
			return isValidValueNode(context, node)
		end,
		BooleanValue = function(_self, node)
			return isValidValueNode(context, node)
		end,
	}
end

-- /**
--  * Any value literal may be a valid representation of a Scalar, depending on
--  * that scalar type.
--  */
function isValidValueNode(context, node)
	-- // Report any error at the full type expected by the location.
	local locationType = context:getInputType()
	if not locationType then
		return
	end

	local type_ = getNamedType(locationType)

	if not isLeafType(type_) then
		local typeStr = inspect(locationType)
		context:reportError(
			GraphQLError.new(
				('Expected value of type "%s", found %s.'):format(
					typeStr,
					print_(node)
				),
				node
			)
		)
		return
	end

	-- // Scalars and Enums determine if a literal value is valid via parseLiteral(),
	-- // which may throw or return an invalid value to indicate failure.
	xpcall(function()
		local parseResult = type_:parseLiteral(node, nil)

		if parseResult == nil then
			local typeStr = inspect(locationType)

			context:reportError(
				GraphQLError.new(
					('Expected value of type "%s", found %s.'):format(typeStr, print_(node)),
					node
				)
			)
		end
	end, function(error_)
		local typeStr = inspect(locationType)
		if instanceOf(error_, GraphQLError) then
			context:reportError(error_)
		else
			context:reportError(
				GraphQLError.new(
					('Expected value of type "%s", found %s; '):format(typeStr, print_(node))
						.. error_.message,
					node,
					nil,
					nil,
					nil,
					error_ -- // Ensure a reference to the original error is maintained.
				)
			)
		end

	end)
end

return exports
