-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/bbd8429b85594d9ee8cc632436e2d0f900d703ef/src/validation/rules/KnownTypeNamesRule.js

local root = script.Parent.Parent.Parent
local jsutils = root.jsutils

-- ROBLOX deviation: use Map type
local Map = require(root.luaUtils.Map)

local didYouMean = require(jsutils.didYouMean).didYouMean
local suggestionList = require(jsutils.suggestionList).suggestionList
local GraphQLError = require(root.error.GraphQLError).GraphQLError
local language = root.language
local predicates = require(language.predicates)
local isTypeDefinitionNode = predicates.isTypeDefinitionNode
local isTypeSystemDefinitionNode = predicates.isTypeSystemDefinitionNode
local isTypeSystemExtensionNode = predicates.isTypeSystemExtensionNode
local typeDirectory = root.type
local specifiedScalarTypes = require(typeDirectory.scalars).specifiedScalarTypes
local introspectionTypes = require(typeDirectory.introspection).introspectionTypes
local Array = require(root.luaUtils.Array)
local PackagesWorkspace = root.Parent.Packages
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Object = LuauPolyfill.Object

local exports = {}

-- ROBLOX deviation: predeclare function
local standardTypeNames
local isStandardTypeName
local isSDLNode

-- /**
--  * Known type names
--  *
--  * A GraphQL document is only valid if referenced types (specifically
--  * variable definitions and fragment conditions) are defined by the type schema.
--  */
exports.KnownTypeNamesRule = function(context)
	local schema = context:getSchema()
	-- ROBLOX deviation: use Map type
	local existingTypesMap = Map.new()
	if schema then
		existingTypesMap = schema:getTypeMap()
	end

	local definedTypes = {}
	for _, def in ipairs(context:getDocument().definitions) do
		if isTypeDefinitionNode(def) then
			definedTypes[def.name.value] = true
		end
	end

	local typeNames = Array.concat(
		-- ROBLOX deviation: use Map type
		existingTypesMap:keys(),
		Object.keys(definedTypes)
	)

	return {
		NamedType = function(_self, node, _1, parent, _2, ancestors)
			local typeName = node.name.value
			-- ROBLOX deviation: use Map type
			if not existingTypesMap:get(typeName) and not definedTypes[typeName] then
				local definitionNode = ancestors[3] or parent
				local isSDL = definitionNode ~= nil and isSDLNode(definitionNode)
				if isSDL and isStandardTypeName(typeName) then
					return
				end

				local suggestedTypes = suggestionList(
					typeName,
					isSDL and Array.concat(standardTypeNames, typeNames) or typeNames
				)

				context:reportError(GraphQLError.new(
					("Unknown type \"%s\"."):format(typeName) .. didYouMean(suggestedTypes),
					node
				))
			end
		end,
	}
end

standardTypeNames = Array.map(Array.concat(specifiedScalarTypes, introspectionTypes), function(type_)
	return type_.name
end)

function isStandardTypeName(typeName: string): boolean
	return Array.indexOf(standardTypeNames, typeName) ~= -1
end

function isSDLNode(value): boolean
	return not Array.isArray(value) and (isTypeSystemDefinitionNode(value) or isTypeSystemExtensionNode(value))
end

return exports
