-- upstream: https://github.com/graphql/graphql-js/blob/056fac955b7172e55b33e0a1b35b4ddb8951a99c/src/type/introspection.js

local srcWorkspace = script.Parent.Parent
local jsutilsWorkspace = srcWorkspace.jsutils
local languageWorkspace = srcWorkspace.language
local Packages = srcWorkspace.Parent

-- ROBLOX deviation: utils
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local isNotNillish = require(srcWorkspace.luaUtils.isNillish).isNotNillish
local Map = require(srcWorkspace.luaUtils.Map).Map

local inspect = require(jsutilsWorkspace.inspect).inspect
local invariant = require(jsutilsWorkspace.invariant).invariant

local print_ = require(languageWorkspace.printer).print
local DirectiveLocation = require(languageWorkspace.directiveLocation).DirectiveLocation
local astFromValue = require(srcWorkspace.utilities.astFromValue).astFromValue

local scalarsModule = require(script.Parent.scalars)
local GraphQLString = scalarsModule.GraphQLString
local GraphQLBoolean = scalarsModule.GraphQLBoolean
local definitionModule = require(script.Parent.definition)
type GraphQLType = definitionModule.GraphQLType
type GraphQLNamedType = definitionModule.GraphQLNamedType
type GraphQLInputField = definitionModule.GraphQLInputField
type GraphQLEnumValue = definitionModule.GraphQLEnumValue
-- ROBLOX TODO: Luau doesn't support default type args, so inline any
type GraphQLField<TSource, TContext> = definitionModule.GraphQLField<TSource, TContext, any>
type GraphQLFieldConfigMap<TSource, TContext> = definitionModule.GraphQLFieldConfigMap<TSource, TContext>

local GraphQLList = definitionModule.GraphQLList
local GraphQLNonNull = definitionModule.GraphQLNonNull
local GraphQLObjectType = definitionModule.GraphQLObjectType
local GraphQLEnumType = definitionModule.GraphQLEnumType
local isScalarType = definitionModule.isScalarType
local isObjectType = definitionModule.isObjectType
local isInterfaceType = definitionModule.isInterfaceType
local isUnionType = definitionModule.isUnionType
local isEnumType = definitionModule.isEnumType
local isInputObjectType = definitionModule.isInputObjectType
local isListType = definitionModule.isListType
local isNonNullType = definitionModule.isNonNullType
local isAbstractType = definitionModule.isAbstractType

-- ROBLOX FIXME: remove any type annotation from exports when Luau can
-- analyze the exports table correctly
local exports: any = {}

exports.__Schema = GraphQLObjectType.new({
	name = "__Schema",
	description = "A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all available types and directives on the server, as well as the entry points for query, mutation, and subscription operations.",
	fields = function()
		return Map.new({
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(schema)
						return schema.description
					end,
				},
			},
			{
				"types",
				{
					description = "A list of all types supported by this server.",
					type = GraphQLNonNull.new(GraphQLList.new(GraphQLNonNull.new(exports.__Type))),
					resolve = function(schema)
						-- ROBLOX deviation: use Map type
						return schema:getTypeMap():values()
					end,
				},
			},
			{
				"queryType",
				{
					description = "The type that query operations will be rooted at.",
					type = GraphQLNonNull.new(exports.__Type),
					resolve = function(schema)
						return schema:getQueryType()
					end,
				},
			},
			{
				"mutationType",
				{
					description = "If this server supports mutation, the type that mutation operations will be rooted at.",
					type = exports.__Type,
					resolve = function(schema)
						return schema:getMutationType()
					end,
				},
			},
			{
				"subscriptionType",
				{
					description = "If this server support subscription, the type that subscription operations will be rooted at.",
					type = exports.__Type,
					resolve = function(schema)
						return schema:getSubscriptionType()
					end,
				},
			},
			{
				"directives",
				{
					description = "A list of all directives supported by this server.",
					type = GraphQLNonNull.new(GraphQLList.new(GraphQLNonNull.new(exports.__Directive))),
					resolve = function(schema)
						return schema:getDirectives()
					end,
				},
			},
		})
	end,
})

exports.__Directive = GraphQLObjectType.new({
	name = "__Directive",
	description = "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.\n\nIn some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.",
	fields = function()
		return Map.new({
			{
				"name",
				{
					type = GraphQLNonNull.new(GraphQLString),
					resolve = function(directive)
						return directive.name
					end,
				},
			},
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(directive)
						return directive.description
					end,
				},
			},
			{
				"isRepeatable",
				{
					type = GraphQLNonNull.new(GraphQLBoolean),
					resolve = function(directive)
						return directive.isRepeatable
					end,
				},
			},
			{
				"locations",
				{
					type = GraphQLNonNull.new(GraphQLList.new(GraphQLNonNull.new(exports.__DirectiveLocation))),
					resolve = function(directive)
						return directive.locations
					end,
				},
			},
			{
				"args",
				{
					type = GraphQLNonNull.new(GraphQLList.new(GraphQLNonNull.new(exports.__InputValue))),
					resolve = function(directive)
						return directive.args
					end,
				},
			},
		})
	end,
})

exports.__DirectiveLocation = GraphQLEnumType.new({
	name = "__DirectiveLocation",
	description = "A Directive can be adjacent to many parts of the GraphQL language, a __DirectiveLocation describes one such possible adjacencies.",
	values = Map.new({
		{
			"QUERY",
			{
				value = DirectiveLocation.QUERY,
				description = "Location adjacent to a query operation.",
			},
		},
		{
			"MUTATION",
			{
				value = DirectiveLocation.MUTATION,
				description = "Location adjacent to a mutation operation.",
			},
		},
		{
			"SUBSCRIPTION",
			{
				value = DirectiveLocation.SUBSCRIPTION,
				description = "Location adjacent to a subscription operation.",
			},
		},
		{
			"FIELD",
			{
				value = DirectiveLocation.FIELD,
				description = "Location adjacent to a field.",
			},
		},
		{
			"FRAGMENT_DEFINITION",
			{
				value = DirectiveLocation.FRAGMENT_DEFINITION,
				description = "Location adjacent to a fragment definition.",
			},
		},
		{
			"FRAGMENT_SPREAD",
			{
				value = DirectiveLocation.FRAGMENT_SPREAD,
				description = "Location adjacent to a fragment spread.",
			},
		},
		{
			"INLINE_FRAGMENT",
			{
				value = DirectiveLocation.INLINE_FRAGMENT,
				description = "Location adjacent to an inline fragment.",
			},
		},
		{
			"VARIABLE_DEFINITION",
			{
				value = DirectiveLocation.VARIABLE_DEFINITION,
				description = "Location adjacent to a variable definition.",
			},
		},
		{
			"SCHEMA",
			{
				value = DirectiveLocation.SCHEMA,
				description = "Location adjacent to a schema definition.",
			},
		},
		{
			"SCALAR",
			{
				value = DirectiveLocation.SCALAR,
				description = "Location adjacent to a scalar definition.",
			},
		},
		{
			"OBJECT",
			{
				value = DirectiveLocation.OBJECT,
				description = "Location adjacent to an object type definition.",
			},
		},
		{
			"FIELD_DEFINITION",
			{
				value = DirectiveLocation.FIELD_DEFINITION,
				description = "Location adjacent to a field definition.",
			},
		},
		{
			"ARGUMENT_DEFINITION",
			{
				value = DirectiveLocation.ARGUMENT_DEFINITION,
				description = "Location adjacent to an argument definition.",
			},
		},
		{
			"INTERFACE",
			{
				value = DirectiveLocation.INTERFACE,
				description = "Location adjacent to an interface definition.",
			},
		},
		{
			"UNION",
			{
				value = DirectiveLocation.UNION,
				description = "Location adjacent to a union definition.",
			},
		},
		{
			"ENUM",
			{
				value = DirectiveLocation.ENUM,
				description = "Location adjacent to an enum definition.",
			},
		},
		{
			"ENUM_VALUE",
			{
				value = DirectiveLocation.ENUM_VALUE,
				description = "Location adjacent to an enum value definition.",
			},
		},
		{
			"INPUT_OBJECT",
			{
				value = DirectiveLocation.INPUT_OBJECT,
				description = "Location adjacent to an input object type definition.",
			},
		},
		{
			"INPUT_FIELD_DEFINITION",
			{
				value = DirectiveLocation.INPUT_FIELD_DEFINITION,
				description = "Location adjacent to an input object field definition.",
			},
		},
	}),
})

exports.__Type = GraphQLObjectType.new({
	name = "__Type",
	description = "The fundamental unit of any GraphQL Schema is the type. There are many kinds of types in GraphQL as represented by the `__TypeKind` enum.\n\nDepending on the kind of a type, certain fields describe information about that type. Scalar types provide no information beyond a name, description and optional `specifiedByUrl`, while Enum types provide their values. Object and Interface types provide the fields they describe. Abstract types, Union and Interface, provide the Object types possible at runtime. List and NonNull types compose other types.",
	fields = function()
		return Map.new({
			{
				"kind",
				{
					type = GraphQLNonNull.new(exports.__TypeKind),
					resolve = function(type_)
						if isScalarType(type_) then
							return exports.TypeKind.SCALAR
						end
						if isObjectType(type_) then
							return exports.TypeKind.OBJECT
						end
						if isInterfaceType(type_) then
							return exports.TypeKind.INTERFACE
						end
						if isUnionType(type_) then
							return exports.TypeKind.UNION
						end
						if isEnumType(type_) then
							return exports.TypeKind.ENUM
						end
						if isInputObjectType(type_) then
							return exports.TypeKind.INPUT_OBJECT
						end
						if isListType(type_) then
							return exports.TypeKind.LIST
						end
						-- // istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
						if isNonNullType(type_) then
							return exports.TypeKind.NON_NULL
						end

						-- // istanbul ignore next (Not reachable. All possible types have been considered)
						invariant(false, ("Unexpected type: \"%s\"."):format(inspect(type_)))
						return nil
					end,
				},
			},
			{
				"name",
				{
					type = GraphQLString,
					resolve = function(type_)
						return (function()
							if type_.name ~= nil then
								return type_.name
							end
							return nil
						end)()
					end,
				},
			},
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(type_)
						return (function()
							if type_.description ~= nil then
								return type_.description
							end
							return nil
						end)()
					end,
				},
			},
			{
				"specifiedByUrl",
				{
					type = GraphQLString,
					resolve = function(obj)
						return (function()
							if obj.specifiedByUrl ~= nil then
								return obj.specifiedByUrl
							end
							return nil
						end)()
					end,
				},
			},
			{
				"fields",
				{
					type = GraphQLList.new(GraphQLNonNull.new(exports.__Field)),
					args = {
						includeDeprecated = {
							type = GraphQLBoolean,
							defaultValue = false,
						},
					},
					resolve = function(type_, args)
						local includeDeprecated = args.includeDeprecated
						if isObjectType(type_) or isInterfaceType(type_) then
							-- ROBLOX deviation: use Map
							local fields = type_:getFields():values()
							return includeDeprecated and fields or Array.filter(fields, function(field)
								return field.deprecationReason == nil
							end)
						end
						return
					end,
				},
			},
			{
				"interfaces",
				{
					type = GraphQLList.new(GraphQLNonNull.new(exports.__Type)),
					resolve = function(type_)
						if isObjectType(type_) or isInterfaceType(type_) then
							return type_:getInterfaces()
						end
						return
					end,
				},
			},
			{
				"possibleTypes",
				{
					type = GraphQLList.new(GraphQLNonNull.new(exports.__Type)),
					resolve = function(type_, _args, _context, _ref)
						local schema = _ref.schema

						if isAbstractType(type_) then
							return schema:getPossibleTypes(type_)
						end
						return nil
					end,
				},
			},
			{
				"enumValues",
				{
					type = GraphQLList.new(GraphQLNonNull.new(exports.__EnumValue)),
					args = {
						includeDeprecated = {
							type = GraphQLBoolean,
							defaultValue = false,
						},
					},
					resolve = function(type_, args)
						local includeDeprecated = args.includeDeprecated

						if isEnumType(type_) then
							local values = type_:getValues()

							return includeDeprecated and values or Array.filter(values, function(field)
								return field.deprecationReason == nil
							end)
						end
						return
					end,
				},
			},
			{
				"inputFields",
				{
					type = GraphQLList.new(GraphQLNonNull.new(exports.__InputValue)),
					args = {
						includeDeprecated = {
							type = GraphQLBoolean,
							defaultValue = false,
						},
					},
					resolve = function(type_, args)
						local includeDeprecated = args.includeDeprecated

						if isInputObjectType(type_) then
							-- ROBLOX deviation: use Map
							local values = type_:getFields():values()

							return includeDeprecated and values or Array.filter(values, function(field)
								return field.deprecationReason == nil
							end)
						end
						return
					end,
				},
			},
			{
				"ofType",
				{
					type = exports.__Type,
					resolve = function(type_)
						return (function()
							if type_.ofType ~= nil then
								return type_.ofType
							end

							return nil
						end)()
					end,
				},
			},
		})
	end,
})

exports.__Field = GraphQLObjectType.new({
	name = "__Field",
	description = "Object and Interface types are described by a list of Fields, each of which has a name, potentially a list of arguments, and a return type.",
	fields = function()
		return Map.new({
			{
				"name",
				{
					type = GraphQLNonNull.new(GraphQLString),
					resolve = function(field)
						return field.name
					end,
				},
			},
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(field)
						return field.description
					end,
				},
			},
			{
				"args",
				{
					type = GraphQLNonNull.new(GraphQLList.new(GraphQLNonNull.new(exports.__InputValue))),
					args = {
						includeDeprecated = {
							type = GraphQLBoolean,
							defaultValue = false,
						},
					},
					resolve = function(field, args)
						local includeDeprecated = args.includeDeprecated

						return (function()
							if includeDeprecated then
								return field.args
							end

							return Array.filter(field.args, function(arg)
								return arg.deprecationReason == nil
							end)
						end)()
					end,
				},
			},
			{
				"type",
				{
					type = GraphQLNonNull.new(exports.__Type),
					resolve = function(field)
						return field.type
					end,
				},
			},
			{
				"isDeprecated",
				{
					type = GraphQLNonNull.new(GraphQLBoolean),
					resolve = function(field)
						return isNotNillish(field.deprecationReason)
					end,
				},
			},
			{
				"deprecationReason",
				{
					type = GraphQLString,
					resolve = function(field)
						return field.deprecationReason
					end,
				},
			},
		})
	end,
})

exports.__InputValue = GraphQLObjectType.new({
	name = "__InputValue",
	description = "Arguments provided to Fields or Directives and the input fields of an InputObject are represented as Input Values which describe their type and optionally a default value.",
	fields = function()
		return Map.new({
			{
				"name",
				{
					type = GraphQLNonNull.new(GraphQLString),
					resolve = function(inputValue)
						return inputValue.name
					end,
				},
			},
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(inputValue)
						return inputValue.description
					end,
				},
			},
			{
				"type",
				{
					type = GraphQLNonNull.new(exports.__Type),
					resolve = function(inputValue)
						return inputValue.type
					end,
				},
			},
			{
				"defaultValue",
				{
					type = GraphQLString,
					description = "A GraphQL-formatted string representing the default value for this input value.",
					resolve = function(inputValue)
						local type_, defaultValue = inputValue.type, inputValue.defaultValue
						local valueAST = astFromValue(defaultValue, type_)
						return (function()
							if valueAST then
								return print_(valueAST)
							end
							return nil
						end)()
					end,
				},
			},
			{
				"isDeprecated",
				{
					type = GraphQLNonNull.new(GraphQLBoolean),
					resolve = function(field)
						return isNotNillish(field.deprecationReason)
					end,
				},
			},
			{
				"deprecationReason",
				{
					type = GraphQLString,
					resolve = function(obj)
						return obj.deprecationReason
					end,
				},
			},
		})
	end,
})

exports.__EnumValue = GraphQLObjectType.new({
	name = "__EnumValue",
	description = "One possible value for a given Enum. Enum values are unique values, not a placeholder for a string or numeric value. However an Enum value is returned in a JSON response as a string.",
	fields = function()
		return Map.new({
			{
				"name",
				{
					type = GraphQLNonNull.new(GraphQLString),
					resolve = function(enumValue)
						return enumValue.name
					end,
				},
			},
			{
				"description",
				{
					type = GraphQLString,
					resolve = function(enumValue)
						return enumValue.description
					end,
				},
			},
			{
				"isDeprecated",
				{
					type = GraphQLNonNull.new(GraphQLBoolean),
					resolve = function(enumValue)
						return isNotNillish(enumValue.deprecationReason)
					end,
				},
			},
			{
				"deprecationReason",
				{
					type = GraphQLString,
					resolve = function(enumValue)
						return enumValue.deprecationReason
					end,
				},
			},
		})
	end,
})

exports.TypeKind = Object.freeze({
	SCALAR = "SCALAR",
	OBJECT = "OBJECT",
	INTERFACE = "INTERFACE",
	UNION = "UNION",
	ENUM = "ENUM",
	INPUT_OBJECT = "INPUT_OBJECT",
	LIST = "LIST",
	NON_NULL = "NON_NULL",
})

exports.__TypeKind = GraphQLEnumType.new({
	name = "__TypeKind",
	description = "An enum describing what kind of type a given `__Type` is.",
	values = Map.new({
		{
			"SCALAR",
			{
				value = exports.TypeKind.SCALAR,
				description = "Indicates this type is a scalar.",
			},
		},
		{
			"OBJECT",
			{
				value = exports.TypeKind.OBJECT,
				description = "Indicates this type is an object. `fields` and `interfaces` are valid fields.",
			},
		},
		{
			"INTERFACE",
			{
				value = exports.TypeKind.INTERFACE,
				description = "Indicates this type is an interface. `fields`, `interfaces`, and `possibleTypes` are valid fields.",
			},
		},
		{
			"UNION",
			{
				value = exports.TypeKind.UNION,
				description = "Indicates this type is a union. `possibleTypes` is a valid field.",
			},
		},
		{
			"ENUM",
			{
				value = exports.TypeKind.ENUM,
				description = "Indicates this type is an enum. `enumValues` is a valid field.",
			},
		},
		{
			"INPUT_OBJECT",
			{
				value = exports.TypeKind.INPUT_OBJECT,
				description = "Indicates this type is an input object. `inputFields` is a valid field.",
			},
		},
		{
			"LIST",
			{
				value = exports.TypeKind.LIST,
				description = "Indicates this type is a list. `ofType` is a valid field.",
			},
		},
		{
			"NON_NULL",
			{
				value = exports.TypeKind.NON_NULL,
				description = "Indicates this type is a non-null. `ofType` is a valid field.",
			},
		},
	}),
})

-- /**
--  * Note that these are GraphQLField and not GraphQLFieldConfig,
--  * so the format for args is different.
--  */

local SchemaMetaFieldDef: GraphQLField<any, any> = {
	name = "__schema",
	type = GraphQLNonNull.new(exports.__Schema),
	description = "Access the current type schema of this server.",
	args = {},
	resolve = function(_source, _args, _context, _ref)
		local schema = _ref.schema

		return schema
	end,
	deprecationReason = nil,
	extensions = nil,
	astNode = nil,
}
exports.SchemaMetaFieldDef = SchemaMetaFieldDef

local TypeMetaFieldDef: GraphQLField<any, any> = {
	name = "__type",
	type = exports.__Type,
	description = "Request the type information of a single type.",
	args = {
		{
			name = "name",
			description = nil,
			type = GraphQLNonNull.new(GraphQLString),
			defaultValue = nil,
			deprecationReason = nil,
			extensions = nil,
			astNode = nil,
		},
	},
	resolve = function(_source, args, _context, _ref)
		local name = args.name
		local schema = _ref.schema

		return schema:getType(name)
	end,
	deprecationReason = nil,
	extensions = nil,
	astNode = nil,
}
exports.TypeMetaFieldDef = TypeMetaFieldDef

local TypeNameMetaFieldDef: GraphQLField<any, any> = {
	name = "__typename",
	type = GraphQLNonNull.new(GraphQLString),
	description = "The name of the current Object type at runtime.",
	args = {},
	resolve = function(_source, _args, _context, _ref)
		local parentType = _ref.parentType

		return parentType.name
	end,
	deprecationReason = nil,
	extensions = nil,
	astNode = nil,
}
exports.TypeNameMetaFieldDef = TypeNameMetaFieldDef

exports.introspectionTypes = Object.freeze({
	exports.__Schema,
	exports.__Directive,
	exports.__DirectiveLocation,
	exports.__Type,
	exports.__Field,
	exports.__InputValue,
	exports.__EnumValue,
	exports.__TypeKind,
})

function exports.isIntrospectionType(type_ --[[: GraphQLNamedType ]])
	return Array.some(exports.introspectionTypes, function(currentType_)
		local name = currentType_.name
		-- ROBLOX deviation: Lua doesn't allow indexing into a function
		return typeof(type_) == "table" and type_.name == name
	end)
end

return exports
