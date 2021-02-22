-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/buildClientSchema.js

local srcWorkspace = script.Parent.Parent
local luaUtilsWorkspace = srcWorkspace.luaUtils

local objectValues = require(srcWorkspace.polyfills.objectValues).objectValues

local inspect = require(srcWorkspace.jsutils.inspect).inspect
local devAssert = require(srcWorkspace.jsutils.devAssert).devAssert
local keyValMap = require(srcWorkspace.jsutils.keyValMap).keyValMap
local isObjectLike = require(srcWorkspace.jsutils.isObjectLike).isObjectLike

local parseValue = require(srcWorkspace.language.parser).parseValue

local GraphQLSchema = require(srcWorkspace.type.schema).GraphQLSchema
local GraphQLDirective = require(srcWorkspace.type.directives).GraphQLDirective
local scalarsImport = require(srcWorkspace.type.scalars)
local specifiedScalarTypes = scalarsImport.specifiedScalarTypes
local introspectionImport = require(srcWorkspace.type.introspection)
local introspectionTypes = introspectionImport.introspectionTypes
local TypeKind = introspectionImport.TypeKind
local definition = require(srcWorkspace.type.definition)
local isInputType = definition.isInputType
local isOutputType = definition.isOutputType
local GraphQLList = definition.GraphQLList
local GraphQLNonNull = definition.GraphQLNonNull
local GraphQLScalarType = definition.GraphQLScalarType
local GraphQLObjectType = definition.GraphQLObjectType
local GraphQLInterfaceType = definition.GraphQLInterfaceType
local GraphQLUnionType = definition.GraphQLUnionType
local GraphQLEnumType = definition.GraphQLEnumType
local GraphQLInputObjectType = definition.GraphQLInputObjectType
local assertNullableType = definition.assertNullableType
local assertObjectType = definition.assertObjectType
local assertInterfaceType = definition.assertInterfaceType

local valueFromAST = require(script.Parent.valueFromAST).valueFromAST

-- ROBLOX deviation: utils
local Error = require(luaUtilsWorkspace.Error)
local Array = require(luaUtilsWorkspace.Array)
local NULL = require(luaUtilsWorkspace.null)
local isNillishModule = require(luaUtilsWorkspace.isNillish)
local isNillish = isNillishModule.isNillish
local isNotNillish = isNillishModule.isNotNillish

--[[*
--  * Build a GraphQLSchema for use by client tools.
--  *
--  * Given the result of a client running the introspection query, creates and
--  * returns a GraphQLSchema instance which can be then used with all graphql-js
--  * tools, but cannot be used to execute a query, as introspection does not
--  * represent the "resolver", "parse" or "serialize" functions or any other
--  * server-internal mechanisms.
--  *
--  * This function expects a complete introspection result. Don't forget to check
--  * the "errors" field of a server response before calling this function.
--  *]]
local function buildClientSchema(introspection, options)
	-- ROBLOX deviation: predeclare functions
	local getType
	local getNamedType
	local getObjectType
	local getInterfaceType
	local buildType
	local buildScalarDef
	local buildImplementationsList
	local buildObjectDef
	local buildInterfaceDef
	local buildUnionDef
	local buildEnumDef
	local buildInputObjectDef
	local buildFieldDefMap
	local buildField
	local buildInputValueDefMap
	local buildInputValue
	local buildDirective

	-- ROBLOX deviation: predeclare variables
	local schemaIntrospection
	local typeMap

	-- ROBLOX deviation: manually hoist all function to the begining of the block

	-- Given a type reference in introspection, return the GraphQLType instance.
	-- preferring cached instances before building new instances.
	function getType(typeRef)
		if typeRef.kind == TypeKind.LIST then
			local itemRef = typeRef.ofType
			if not itemRef then
				error(Error.new("Decorated type deeper than introspection query."))
			end

			return GraphQLList.new(getType(itemRef))
		end
		if typeRef.kind == TypeKind.NON_NULL then
			local nullableRef = typeRef.ofType
			if not nullableRef then
				error(Error.new("Decorated type deeper than introspection query."))
			end
			local nullableType = getType(nullableRef)

			return GraphQLNonNull.new(assertNullableType(nullableType))
		end
		return getNamedType(typeRef)
	end

	function getNamedType(typeRef)
		local typeName = typeRef.name
		if isNillish(typeName) then
			error(Error.new(("Unknown type reference: %s."):format(inspect(typeRef))))
		end

		local type_ = typeMap[typeName]
		if isNillish(type_) then
			error(Error.new(("Invalid or incomplete schema, unknown type: %s. Ensure that a full introspection query is used in order to build a client schema."):format(typeName)))
		end

		return type_
	end

	function getObjectType(typeRef)
		return assertObjectType(getNamedType(typeRef))
	end

	function getInterfaceType(typeRef)
		return assertInterfaceType(getNamedType(typeRef))
	end

	-- Given a type's introspection result, construct the correct
	-- GraphQLType instance.
	function buildType(type_)
		if isNotNillish(type_) and isNotNillish(type_.name) and isNotNillish(type_.kind) then
			if type_.kind == TypeKind.SCALAR then
				return buildScalarDef(type_)
			elseif type_.kind == TypeKind.OBJECT then
				return buildObjectDef(type_)
			elseif type_.kind == TypeKind.INTERFACE then
				return buildInterfaceDef(type_)
			elseif type_.kind == TypeKind.UNION then
				return buildUnionDef(type_)
			elseif type_.kind == TypeKind.ENUM then
				return buildEnumDef(type_)
			elseif type_.kind == TypeKind.INPUT_OBJECT then
				return buildInputObjectDef(type_)
			end
		end
		local typeStr = inspect(type_)
		error(Error.new(("Invalid or incomplete introspection result. Ensure that a full introspection query is used in order to build a client schema: %s."):format(typeStr)))
	end

	function buildScalarDef(scalarIntrospection)
		return GraphQLScalarType.new({
			name = scalarIntrospection.name,
			description = scalarIntrospection.description,
			specifiedByUrl = scalarIntrospection.specifiedByUrl,
		})
	end

	function buildImplementationsList(implementingIntrospection)
		-- TODO: Temporary workaround until GraphQL ecosystem will fully support
		-- 'interfaces' on interface types.
		if implementingIntrospection.interfaces == nil and implementingIntrospection.kind == TypeKind.INTERFACE then
			return {}
		end

		if not implementingIntrospection.interfaces then
			local implementingIntrospectionStr = inspect(implementingIntrospection)
			error(Error.new(("Introspection result missing interfaces: %s."):format(implementingIntrospectionStr)))
		end

		return Array.map(implementingIntrospection.interfaces, getInterfaceType)
	end

	function buildObjectDef(objectIntrospection)
		return GraphQLObjectType.new({
			name = objectIntrospection.name,
			description = objectIntrospection.description,
			interfaces = function()
				return buildImplementationsList(objectIntrospection)
			end,
			fields = function()
				return buildFieldDefMap(objectIntrospection)
			end,
		})
	end

	function buildInterfaceDef(interfaceIntrospection)
		return GraphQLInterfaceType.new({
			name = interfaceIntrospection.name,
			description = interfaceIntrospection.description,
			interfaces = function()
				return buildImplementationsList(interfaceIntrospection)
			end,
			fields = function()
				return buildFieldDefMap(interfaceIntrospection)
			end,
		})
	end

	function buildUnionDef(unionIntrospection)
		if not unionIntrospection.possibleTypes then
			local unionIntrospectionStr = inspect(unionIntrospection)
			error(Error.new(("Introspection result missing possibleTypes: %s."):format(unionIntrospectionStr)))
		end

		return GraphQLUnionType.new({
			name = unionIntrospection.name,
			description = unionIntrospection.description,
			types = function()
				return Array.map(unionIntrospection.possibleTypes, getObjectType)
			end,
		})
	end

	function buildEnumDef(enumIntrospection)
		if not enumIntrospection.enumValues then
			local enumIntrospectionStr = inspect(enumIntrospection)
			error(Error.new(("Introspection result missing enumValues: %s."):format(enumIntrospectionStr)))
		end
		return GraphQLEnumType.new({
			name = enumIntrospection.name,
			description = enumIntrospection.description,
			values = keyValMap(enumIntrospection.enumValues, function(valueIntrospection)
				return valueIntrospection.name
			end, function(valueIntrospection)
				return {
					description = valueIntrospection.description,
					deprecationReason = valueIntrospection.deprecationReason,
				}
			end),
		})
	end

	function buildInputObjectDef(inputObjectIntrospection)
		if not inputObjectIntrospection.inputFields then
			local inputObjectIntrospectionStr = inspect(inputObjectIntrospection)
			error(Error.new(("Introspection result missing inputFields: %s."):format(inputObjectIntrospectionStr)))
		end
		return GraphQLInputObjectType.new({
			name = inputObjectIntrospection.name,
			description = inputObjectIntrospection.description,
			fields = function()
				return buildInputValueDefMap(inputObjectIntrospection.inputFields)
			end,
		})
	end

	function buildFieldDefMap(typeIntrospection)
		if not typeIntrospection.fields then
			error(Error.new(("Introspection result missing fields: %s."):format(inspect(typeIntrospection))))
		end

		return keyValMap(
			typeIntrospection.fields,
			function(fieldIntrospection)
				return fieldIntrospection.name
			end,
			buildField
		)
	end

	function buildField(fieldIntrospection)
		local type_ = getType(fieldIntrospection.type)
		if not isOutputType(type_) then
			local typeStr = inspect(type_)
			error(Error.new(("Introspection must provide output type for fields, but received: %s."):format(typeStr)))
		end

		if not fieldIntrospection.args then
			local fieldIntrospectionStr = inspect(fieldIntrospection)

			error(Error.new(("Introspection result missing field args: %s."):format(fieldIntrospectionStr)))
		end

		return {
			description = fieldIntrospection.description,
			deprecationReason = fieldIntrospection.deprecationReason,
			type = type_,
			args = buildInputValueDefMap(fieldIntrospection.args),
		}
	end

	function buildInputValueDefMap(inputValueIntrospections)
		return keyValMap(
			inputValueIntrospections,
			function(inputValue)
				return inputValue.name
			end,
			buildInputValue
		)
	end

	function buildInputValue(inputValueIntrospection)
		local type_ = getType(inputValueIntrospection.type)
		if not isInputType(type_) then
			local typeStr = inspect(type_)
			error(Error.new(("Introspection must provide input type for arguments, but received: %s."):format(typeStr)))
		end

		local defaultValue = (function()
			if isNotNillish(inputValueIntrospection.defaultValue) then
				return valueFromAST(parseValue(inputValueIntrospection.defaultValue), type_)
			end
			return nil
		end)()
		return {
			description = inputValueIntrospection.description,
			type = type_,
			defaultValue = defaultValue,
			deprecationReason = inputValueIntrospection.deprecationReason,
		}
	end

	function buildDirective(directiveIntrospection)
		if not directiveIntrospection.args then
			local directiveIntrospectionStr = inspect(directiveIntrospection)

			error(Error.new(("Introspection result missing directive args: %s."):format(directiveIntrospectionStr)))
		end
		if not directiveIntrospection.locations then
			local directiveIntrospectionStr = inspect(directiveIntrospection)
			error(Error.new(("Introspection result missing directive locations: %s."):format(directiveIntrospectionStr)))
		end
		return GraphQLDirective.new({
			name = directiveIntrospection.name,
			description = directiveIntrospection.description,
			isRepeatable = directiveIntrospection.isRepeatable,
			locations = Array.slice(directiveIntrospection.locations),
			args = buildInputValueDefMap(directiveIntrospection.args),
		})
	end

	devAssert(
		isObjectLike(introspection) and isObjectLike(introspection.__schema),
		("Invalid or incomplete introspection result. Ensure that you are passing \"data\" property of introspection response and no \"errors\" was returned alongside: %s."):format(inspect(introspection))
	)

	-- Get the schema from the introspection result.
	schemaIntrospection = introspection.__schema

	-- Iterate through all types, getting the type definition for each.
	typeMap = keyValMap(schemaIntrospection.types, function(typeIntrospection)
		return typeIntrospection.name
	end, function(typeIntrospection)
		return buildType(typeIntrospection)
	end)

	-- Include standard types only if they are used.
	for _, stdType in ipairs(Array.concat(specifiedScalarTypes, introspectionTypes)) do
		if typeMap[stdType.name] then
			typeMap[stdType.name] = stdType
		end
	end

	-- Get the root Query, Mutation, and Subscription types.
	local queryType = (function()
		if isNotNillish(schemaIntrospection.queryType) then
			return getObjectType(schemaIntrospection.queryType)
		end
		return NULL
	end)()

	local mutationType = (function()
		if isNotNillish(schemaIntrospection.mutationType) then
			return getObjectType(schemaIntrospection.mutationType)
		end
		return NULL
	end)()

	local subscriptionType = (function()
		if isNotNillish(schemaIntrospection.subscriptionType) then
			return getObjectType(schemaIntrospection.subscriptionType)
		end
		return NULL
	end)()

	-- Get the directives supported by Introspection, assuming empty-set if
	-- directives were not queried for.
	local directives = (function()
		if isNotNillish(schemaIntrospection.directives) then
			return Array.map(schemaIntrospection.directives, buildDirective)
		end
		return {}
	end)()

	-- Then produce and return a Schema with these types.
	return GraphQLSchema.new({
		description = schemaIntrospection.description,
		query = queryType,
		mutation = mutationType,
		subscription = subscriptionType,
		types = objectValues(typeMap),
		directives = directives,
		assumeValid = options and options.assumeValid,
	})
end

return {
	buildClientSchema = buildClientSchema,
}
