-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/lexicographicSortSchema.js

-- ROBLOX deviation: add polyfills
local srcWorkspace = script.Parent.Parent
local rootWorkspace = srcWorkspace.Parent
local LuauPolyfill = require(rootWorkspace.Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local MapModule = require(srcWorkspace.luaUtils.Map)
local Map = MapModule.Map
type Map<T, V> = MapModule.Map<T, V>
type Array<T> = { [number]: T }

local inspect = require(srcWorkspace.jsutils.inspect).inspect
local invariant = require(srcWorkspace.jsutils.invariant).invariant
-- ROBLOX deviation: use Map Type
local keyValMapOrdered = require(srcWorkspace.luaUtils.keyValMapOrdered).keyValMapOrdered
local naturalCompare = require(srcWorkspace.jsutils.naturalCompare).naturalCompare

local SchemaModule = require(srcWorkspace.type.schema)
local GraphQLSchema = SchemaModule.GraphQLSchema
-- ROBLOX deviation: bring in types separately
type GraphQLSchema = SchemaModule.GraphQLSchema
local GraphQLDirective = require(srcWorkspace.type.directives).GraphQLDirective

local DefinitionModule = require(srcWorkspace.type.definition)
type GraphQLType = any -- DefinitionModule.GraphQLType
type GraphQLNamedType = any -- DefinitionModule.GraphQLNamedType
type GraphQLFieldConfigMap<T,V> = any -- DefinitionModule.GraphQLFieldConfigMap
type GraphQLFieldConfigArgumentMap = any -- DefinitionModule.GraphQLFieldConfigArgumentMap
type GraphQLInputFieldConfigMap = any -- DefinitionModule.GraphQLInputFieldConfigMap

local isIntrospectionType = require(srcWorkspace.type.introspection).isIntrospectionType
local GraphQLList = DefinitionModule.GraphQLList
local GraphQLNonNull = DefinitionModule.GraphQLNonNull
local GraphQLObjectType = DefinitionModule.GraphQLObjectType
local GraphQLInterfaceType = DefinitionModule.GraphQLInterfaceType
local GraphQLUnionType = DefinitionModule.GraphQLUnionType
local GraphQLEnumType = DefinitionModule.GraphQLEnumType
local GraphQLInputObjectType = DefinitionModule.GraphQLInputObjectType
local isListType = DefinitionModule.isListType
local isNonNullType = DefinitionModule.isNonNullType
local isScalarType = DefinitionModule.isScalarType
local isObjectType = DefinitionModule.isObjectType
local isInterfaceType = DefinitionModule.isInterfaceType
local isUnionType = DefinitionModule.isUnionType
local isEnumType = DefinitionModule.isEnumType
local isInputObjectType = DefinitionModule.isInputObjectType

-- ROBLOX deviation: predeclare variables
local sortObjMap, sortByName, sortBy

--[[
 * Sort GraphQLSchema.
 *
 * This function returns a sorted copy of the given GraphQLSchema.
 *]]
local function lexicographicSortSchema(
	schema: GraphQLSchema
): GraphQLSchema
	-- ROBLOX deviation: predeclare variables
	local typeMap

	-- ROBLOX deviation: predeclare functions
	local replaceType, replaceNamedType, replaceMaybeType, sortDirective, sortArgs, sortFields, sortInputFields, sortTypes, sortNamedType

	-- ROBLOX deviation hoist all functions to top of scope
	function replaceType(type_)
		if isListType(type_) then
			-- $FlowFixMe[incompatible-return]
			return GraphQLList.new(replaceType(type_.ofType))
		elseif isNonNullType(type_) then
			-- $FlowFixMe[incompatible-return]
			return GraphQLNonNull.new(replaceType(type_.ofType))
		end

		return replaceNamedType(type_)
	end

	function replaceNamedType(type_)
		return typeMap:get(type_.name)
	end

	function replaceMaybeType(maybeType)
		return maybeType and replaceNamedType(maybeType)
	end

	function sortDirective(directive)
		local config = directive:toConfig()

		return GraphQLDirective.new(Object.assign({}, config, {
			locations = sortBy(config.locations, function(x)
				return x
			end),
			args = sortArgs(config.args),
		}))
	end

	function sortArgs(args: GraphQLFieldConfigArgumentMap)
		return sortObjMap(args, function(arg)
			return Object.assign({}, arg, {
				type = replaceType(arg.type),
			})
		end)
	end

	function sortFields(fieldsMap: GraphQLFieldConfigMap<any, any>)
		return sortObjMap(fieldsMap, function(field)
			return Object.assign({}, field, {
				type = replaceType(field.type),
				args = sortArgs(field.args),
			})
		end)
	end

	function sortInputFields(fieldsMap: GraphQLInputFieldConfigMap)
		return sortObjMap(fieldsMap, function(field)
			return Object.assign({}, field, {
				type = replaceType(field.type),
			})
		end)
	end

	function sortTypes(arr: Array<any>) : Array<any>
		return Array.map(sortByName(arr), replaceNamedType)
	end

	function sortNamedType(type_: GraphQLNamedType): GraphQLNamedType
		if isScalarType(type_) or isIntrospectionType(type_) then
			return type_
		end
		if isObjectType(type_) then
			local config = type_:toConfig()

			return GraphQLObjectType.new(Object.assign({}, config, {
				interfaces = function()
					return sortTypes(config.interfaces)
				end,
				fields = function()
					return sortFields(config.fields)
				end,
			}))
		end
		if isInterfaceType(type_) then
			local config = type_:toConfig()

			return GraphQLInterfaceType.new(Object.assign({}, config, {
				interfaces = function()
					return sortTypes(config.interfaces)
				end,
				fields = function()
					return sortFields(config.fields)
				end,
			}))
		end
		if isUnionType(type_) then
			local config = type_:toConfig()

			return GraphQLUnionType.new(Object.assign({}, config, {
				types = function()
					return sortTypes(config.types)
				end,
			}))
		end
		if isEnumType(type_) then
			local config = type_:toConfig()

			return GraphQLEnumType.new(Object.assign({}, config, {
				values = sortObjMap(config.values),
			}))
		end
		-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
		if isInputObjectType(type_) then
			local config = type_:toConfig()

			return GraphQLInputObjectType.new(Object.assign({}, config, {
				fields = function()
					return sortInputFields(config.fields)
				end,
			}))
		end

		-- istanbul ignore next (Not reachable. All possible types have been considered)
		invariant(false, "Unexpected type: " .. inspect(type_))
		error("Unexpected type: " .. inspect(type_)) -- ROBLOX deviation: analyze implicit return value
	end

	local schemaConfig = schema:toConfig()
	typeMap = keyValMapOrdered(
		sortByName(schemaConfig.types),
		function(type_)
			return type_.name
		end,
		sortNamedType
	)

	return GraphQLSchema.new(Object.assign({}, schemaConfig, {
		types = typeMap:values(),
		directives = Array.map(sortByName(schemaConfig.directives), sortDirective),
		query = replaceMaybeType(schemaConfig.query),
		mutation = replaceMaybeType(schemaConfig.mutation),
		subscription = replaceMaybeType(schemaConfig.subscription),
	}))
end

function sortObjMap(
	map: Map<string, any>,
	sortValueFn: (any) -> any
): Map<string, any>
	local sortedMap = Map.new()
	local sortedKeys = sortBy(map:keys(), function(x)
		return x
	end)

	for _, key in ipairs(sortedKeys) do
		local value = map:get(key)
		sortedMap:set(
			key,
			(function()
				if sortValueFn ~= nil then
					return sortValueFn(value)
				end

				return value
			end)()
		)
	end

	return sortedMap
end

function sortByName(array: Array<any>): Array<any>
	return sortBy(array, function(obj)
		return obj.name
	end)
end

function sortBy(
	array: Array<any>,
	mapToKey: (any) -> string
): Array<any>
	return Array.sort(Array.slice(array), function(obj1, obj2)
		local key1 = mapToKey(obj1)
		local key2 = mapToKey(obj2)
		return naturalCompare(key1, key2)
	end)
end

return {
	lexicographicSortSchema = lexicographicSortSchema,
}
