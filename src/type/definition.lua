-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/type/definition.js

type Array<T> = { [number]: T }
local srcWorkspace = script.Parent.Parent

local objectEntries = require(srcWorkspace.polyfills.objectEntries).objectEntries

local jsutilsWorkspace = srcWorkspace.jsutils
local inspect = require(jsutilsWorkspace.inspect).inspect
local keyMap = require(jsutilsWorkspace.keyMap).keyMap
local mapValue = require(jsutilsWorkspace.mapValue).mapValue
local toObjMap = require(jsutilsWorkspace.toObjMap).toObjMap
local devAssert = require(jsutilsWorkspace.devAssert).devAssert
local keyValMap = require(jsutilsWorkspace.keyValMap).keyValMap
local instanceOf = require(jsutilsWorkspace.instanceOf)
local didYouMean = require(jsutilsWorkspace.didYouMean).didYouMean
local isObjectLike = require(jsutilsWorkspace.isObjectLike).isObjectLike
local identityFunc = require(jsutilsWorkspace.identityFunc).identityFunc
local suggestionList = require(jsutilsWorkspace.suggestionList).suggestionList

local GraphQLError = require(srcWorkspace.error.GraphQLError).GraphQLError

local languageWorkspace = srcWorkspace.language
local Kind = require(languageWorkspace.kinds).Kind
local print_ = require(languageWorkspace.printer).print

local valueFromASTUntyped = require(srcWorkspace.utilities.valueFromASTUntyped).valueFromASTUntyped

local Error = require(srcWorkspace.luaUtils.Error)
-- ROBLOX deviation: no distinction between undefined and null in Lua so we need to go around this with custom NULL like constant
local NULL = require(srcWorkspace.luaUtils.null)
local Array = require(srcWorkspace.Parent.Packages.LuauPolyfill).Array

-- ROBLOX deviation: predeclare functions
local isType
local assertType
local isScalarType
local assertScalarType
local isObjectType
local assertObjectType
local isInterfaceType
local assertInterfaceType
local isUnionType
local assertUnionType
local isEnumType
local assertEnumType
local isInputObjectType
local assertInputObjectType
local isListType
local assertListType
local isNonNullType
local assertNonNullType
local isInputType
local assertInputType
local isOutputType
local assertOutputType
local isLeafType
local assertLeafType
local isCompositeType
local assertCompositeType
local isAbstractType
local assertAbstractType
local isWrappingType
local assertWrappingType
local isNullableType
local assertNullableType
local getNullableType
local isNamedType
local assertNamedType
local getNamedType
local argsToArgsConfig
local isRequiredArgument
local isRequiredInputField
local defineInputFieldMap
local defineTypes
local isPlainObj
local didYouMeanEnumValue
local defineEnumValues
local fieldsToFieldsConfig
local defineInterfaces
local defineFieldMap

-- ROBLOX deviation: predeclare classes
local GraphQLList
local GraphQLNonNull
local GraphQLScalarType
local GraphQLObjectType
local GraphQLInterfaceType
local GraphQLUnionType
local GraphQLEnumType
local GraphQLInputObjectType

function isType(type_)
	return isScalarType(type_) or isObjectType(type_) or isInterfaceType(type_) or isUnionType(type_) or isEnumType(type_) or isInputObjectType(type_) or isListType(type_) or isNonNullType(type_)
end

function assertType(type_)
	if not isType(type_) then
		error(Error.new(("Expected %s to be a GraphQL type."):format(inspect(type_))))
	end

	return type_
end

--[[*
--  * There are predicates for each kind of GraphQL type.
--  *]]

function isScalarType(type_)
	return instanceOf(type_, GraphQLScalarType)
end

function assertScalarType(type_)
	if not isScalarType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Scalar type."):format(inspect(type_))))
	end

	return type_
end

function isObjectType(type_)
	return instanceOf(type_, GraphQLObjectType)
end

function assertObjectType(type_)
	if not isObjectType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Object type."):format(inspect(type_))))
	end

	return type_
end

function isInterfaceType(type_)
	return instanceOf(type_, GraphQLInterfaceType)
end

function assertInterfaceType(type_)
	if not isInterfaceType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Interface type."):format(inspect(type_))))
	end

	return type_
end

function isUnionType(type_)
	return instanceOf(type_, GraphQLUnionType)
end

function assertUnionType(type_)
	if not isUnionType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Union type."):format(inspect(type_))))
	end

	return type_
end

function isEnumType(type_)
	return instanceOf(type_, GraphQLEnumType)
end

function assertEnumType(type_)
	if not isEnumType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Enum type."):format(inspect(type_))))
	end

	return type_
end

function isInputObjectType(type_)
	return instanceOf(type_, GraphQLInputObjectType)
end

function assertInputObjectType(type_)
	if not isInputObjectType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Input Object type."):format(inspect(type_))))
	end

	return type_
end

function isListType(type_)
	return instanceOf(type_, GraphQLList)
end

function assertListType(type_)
	if not isListType(type_) then
		error(Error.new(("Expected %s to be a GraphQL List type."):format(inspect(type_))))
	end

	return type_
end

function isNonNullType(type_)
	return instanceOf(type_, GraphQLNonNull)
end

function assertNonNullType(type_)
	if not isNonNullType(type_) then
		error(Error.new(("Expected %s to be a GraphQL Non-Null type."):format(inspect(type_))))
	end

	return type_
end

function isInputType(type_)
	return isScalarType(type_) or isEnumType(type_) or isInputObjectType(type_) or isWrappingType(type_) and isInputType(type_.ofType)
end

function assertInputType(type_)
	if not isInputType(type_) then
		error(Error.new(("Expected %s to be a GraphQL input type."):format(inspect(type_))))
	end

	return type_
end

function isOutputType(type_)
	return isScalarType(type_) or isObjectType(type_) or isInterfaceType(type_) or isUnionType(type_) or isEnumType(type_) or isWrappingType(type_) and isOutputType(type_.ofType)
end

function assertOutputType(type_)
	if not isOutputType(type_) then
		error(Error.new(("Expected %s to be a GraphQL output type."):format(inspect(type_))))
	end

	return type_
end

function isLeafType(type_)
	return isScalarType(type_) or isEnumType(type_)
end

function assertLeafType(type_)
	if not isLeafType(type_) then
		error(Error.new(("Expected %s to be a GraphQL leaf type."):format(inspect(type_))))
	end

	return type_
end

function isCompositeType(type_)
	return isObjectType(type_) or isInterfaceType(type_) or isUnionType(type_)
end

function assertCompositeType(type_)
	if not isCompositeType(type_) then
		error(Error.new(("Expected %s to be a GraphQL composite type."):format(inspect(type_))))
	end

	return type_
end

function isAbstractType(type_)
	return isInterfaceType(type_) or isUnionType(type_)
end

function assertAbstractType(type_)
	if not isAbstractType(type_) then
		error(Error.new(("Expected %s to be a GraphQL abstract type."):format(inspect(type_))))
	end

	return type_
end

-- /**
--  * List Type Wrapper
--  *
--  * A list is a wrapping type which points to another type.
--  * Lists are often created within the context of defining the fields of
--  * an object type.
--  *
--  * Example:
--  *
--  *     const PersonType = new GraphQLObjectType({
--  *       name: 'Person',
--  *       fields: () => ({
--  *         parents: { type: new GraphQLList(PersonType) },
--  *         children: { type: new GraphQLList(PersonType) },
--  *       })
--  *     })
--  *
--  */
GraphQLList = {}

GraphQLList.__index = GraphQLList

function GraphQLList.new(ofType)
	local self = {}

	devAssert(
		isType(ofType),
		("Expected %s to be a GraphQL type."):format(inspect(ofType))
	)

	self.ofType = ofType

	return setmetatable(self, GraphQLList)
end

function GraphQLList.__tostring(self)
	return self:toString()
end

function GraphQLList.toString(self)
	return "[" .. tostring(self.ofType) .. "]"
end

function GraphQLList.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLList';
--   }
-- }

-- /**
--  * Non-Null Type Wrapper
--  *
--  * A non-null is a wrapping type which points to another type.
--  * Non-null types enforce that their values are never null and can ensure
--  * an error is raised if this ever occurs during a request. It is useful for
--  * fields which you can make a strong guarantee on non-nullability, for example
--  * usually the id field of a database row will never be null.
--  *
--  * Example:
--  *
--  *     const RowType = new GraphQLObjectType({
--  *       name: 'Row',
--  *       fields: () => ({
--  *         id: { type: new GraphQLNonNull(GraphQLString) },
--  *       })
--  *     })
--  *
--  * Note: the enforcement of non-nullability occurs within the executor.
--  */
GraphQLNonNull = {}

GraphQLNonNull.__index = GraphQLNonNull

function GraphQLNonNull.new(ofType)
	local self = {}
	devAssert(
		isNullableType(ofType),
		("Expected %s to be a GraphQL nullable type."):format(inspect(ofType))
	)

	self.ofType = ofType
	return setmetatable(self, GraphQLNonNull)
end

function GraphQLNonNull.__tostring(self)
	return self:toString()
end

function GraphQLNonNull.toString(self)
	return tostring(self.ofType) .. "!"
end

function GraphQLNonNull.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLNonNull';
--   }
-- }

function isWrappingType(type_)
	return isListType(type_) or isNonNullType(type_)
end

function assertWrappingType(type_)
	if not isWrappingType(type_) then
		error(Error.new(("Expected %s to be a GraphQL wrapping type."):format(inspect(type_))))
	end

	return type_
end

function isNullableType(type_)
	return isType(type_) and not isNonNullType(type_)
end

function assertNullableType(type_)
	if not isNullableType(type_) then
		error(Error.new(("Expected %s to be a GraphQL nullable type."):format(inspect(type_))))
	end

	return type_
end

function getNullableType(type_)
	if type_ then
		return (function()
			if isNonNullType(type_) then
				return type_.ofType
			end

			return type_
		end)()
	end

	-- ROBLOX deviation: upstream JS implicitly returns undefined
	return nil
end

function isNamedType(type_)
	return isScalarType(type_) or isObjectType(type_) or isInterfaceType(type_) or isUnionType(type_) or isEnumType(type_) or isInputObjectType(type_)
end

function assertNamedType(type_)
	if not isNamedType(type_) then
		error(Error.new(("Expected %s to be a GraphQL named type."):format(inspect(type_))))
	end

	return type_
end

function getNamedType(type_)
	if type_ then
		local unwrappedType = type_

		while isWrappingType(unwrappedType) do
			unwrappedType = unwrappedType.ofType
		end

		return unwrappedType
	end

	-- ROBLOX deviation: upstream JS implicitly returns undefined
	return nil
end

local function resolveThunk(thunk)
	return (function()
		if typeof(thunk) == "function" then
			return thunk()
		end

		return thunk
	end)()
end

local function undefineIfEmpty(arr)
	return (function()
		if arr and #arr > 0 then
			return arr
		end

		return nil
	end)()
end

--[[*
--  * Scalar Type Definition
--  *
--  * The leaf values of any request and input values to arguments are
--  * Scalars (or Enums) and are defined with a name and a series of functions
--  * used to parse input from ast or variables and to ensure validity.
--  *
--  * If a type's serialize function does not return a value (i.e. it returns
--  * `undefined`) then an error will be raised and a `null` value will be returned
--  * in the response. If the serialize function returns `null`, then no error will
--  * be included in the response.
--  *
--  * Example:
--  *
--  *     const OddType = new GraphQLScalarType({
--  *       name: 'Odd',
--  *       serialize(value) {
--  *         if (value % 2 === 1) {
--  *           return value;
--  *         }
--  *       }
--  *     });
--  *
--  *]]
GraphQLScalarType = {}

GraphQLScalarType.__index = GraphQLScalarType

function GraphQLScalarType.new(config)
	local self = {}
	local parseValue
	if config.parseValue then
		parseValue = config.parseValue
	else
		parseValue = identityFunc
	end
	self.name = config.name
	self.description = config.description
	self.specifiedByUrl = config.specifiedByUrl
	-- ROBLOX devation: we need to wrap the actual function to handle the `self` param correctly
	local serialize = (function()
		local _ref = config.serialize

		if _ref == nil then
			_ref = identityFunc
		end
		return _ref
	end)()
	self.serialize = function(_, ...)
		return serialize(...)
	end
	-- ROBLOX devation: we need to wrap the actual function to handle the `self` param correctly
	self.parseValue = function(_, ...)
		return parseValue(...)
	end
	-- ROBLOX devation: we need to wrap the actual function to handle the `self` param correctly
	local parseLiteral = (function()
		local _ref = config.parseLiteral

		if _ref == nil then
			_ref = function(node, variables)
				return parseValue(valueFromASTUntyped(node, variables))
			end
		end
		return _ref
	end)()
	self.parseLiteral = function(_, ...)
		return parseLiteral(...)
	end
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	devAssert(typeof(config.name) == "string", "Must provide name.")

	devAssert(
		config.specifiedByUrl == nil or typeof(config.specifiedByUrl) == "string",
		("%s must provide \"specifiedByUrl\" as a string, "):format(self.name) .. ("but got: %s."):format(inspect(config.specifiedByUrl))
	)

	devAssert(
		config.serialize == nil or typeof(config.serialize) == "function",
		("%s must provide \"serialize\" function. If this custom Scalar is also used as an input type, ensure \"parseValue\" and \"parseLiteral\" functions are also provided."):format(self.name)
	)

	if config.parseLiteral then
		devAssert(
			typeof(config.parseValue) == "function" and typeof(config.parseLiteral) == "function",
			("%s must provide both \"parseValue\" and \"parseLiteral\" functions."):format(self.name)
		)
	end

	return setmetatable(self, GraphQLScalarType)
end

function GraphQLScalarType.toConfig(self)
	return {
		name = self.name,
		description = self.description,
		specifiedByUrl = self.specifiedByUrl,
		serialize = self.serialize,
		parseValue = self.parseValue,
		parseLiteral = self.parseLiteral,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = (function()
			local _ref = self.extensionASTNodes

			if _ref == nil then
				_ref = {}
			end
			return _ref
		end)(),
	}
end

function GraphQLScalarType.__tostring(self)
	return self:toString()
end

function GraphQLScalarType.toString(self)
	return self.name
end

function GraphQLScalarType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLScalarType';
--   }
-- }

--[[*
--  * Object Type Definition
--  *
--  * Almost all of the GraphQL types you define will be object types. Object types
--  * have a name, but most importantly describe their fields.
--  *
--  * Example:
--  *
--  *     const AddressType = new GraphQLObjectType({
--  *       name: 'Address',
--  *       fields: {
--  *         street: { type: GraphQLString },
--  *         number: { type: GraphQLInt },
--  *         formatted: {
--  *           type: GraphQLString,
--  *           resolve(obj) {
--  *             return obj.number + ' ' + obj.street
--  *           }
--  *         }
--  *       }
--  *     });
--  *
--  * When two types need to refer to each other, or a type needs to refer to
--  * itself in a field, you can use a function expression (aka a closure or a
--  * thunk) to supply the fields lazily.
--  *
--  * Example:
--  *
--  *     const PersonType = new GraphQLObjectType({
--  *       name: 'Person',
--  *       fields: () => ({
--  *         name: { type: GraphQLString },
--  *         bestFriend: { type: PersonType },
--  *       })
--  *     });
--  *
--  *]]
GraphQLObjectType = {}
GraphQLObjectType.__index = GraphQLObjectType

function GraphQLObjectType.new(config)
	local self = {}
	self.name = config.name
	self.description = config.description
	self.isTypeOf = config.isTypeOf
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	self._fields = function()
		return defineFieldMap(config)
	end
	self._interfaces = function()
		return defineInterfaces(config)
	end
	devAssert(typeof(config.name) == "string", "Must provide name.")
	devAssert(
		config.isTypeOf == nil or typeof(config.isTypeOf) == "function",
		("%s must provide \"isTypeOf\" as a function, " .. "but got: %s."):format(self.name, inspect(config.isTypeOf))
	)

	return setmetatable(self, GraphQLObjectType)
end

function GraphQLObjectType:getFields()
	if typeof(self._fields) == "function" then
		self._fields = self._fields()
	end
	return self._fields
end

function GraphQLObjectType:getInterfaces(): Array<any>
	if typeof(self._interfaces) == "function" then
		self._interfaces = self._interfaces()
	end
	return self._interfaces
end

function GraphQLObjectType:toConfig()
	return {
		name = self.name,
		description = self.description,
		interfaces = self:getInterfaces(),
		fields = fieldsToFieldsConfig(self:getFields()),
		isTypeOf = self.isTypeOf,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = self.extensionASTNodes or {},
	}
end

function GraphQLObjectType.__tostring(self)
	return self:toString()
end

function GraphQLObjectType.toString(self)
	return self.name
end

function GraphQLObjectType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLObjectType';
--   }
-- }

function defineInterfaces(config)
	local interfaces = (function()
		local _ref = resolveThunk(config.interfaces)

		if _ref == nil then
			_ref = {}
		end
		return _ref
	end)()

	devAssert(
		Array.isArray(interfaces),
		("%s interfaces must be an Array or a function which returns an Array."):format(config.name)
	)

	return interfaces
end

function defineFieldMap(config)
	local fieldMap = resolveThunk(config.fields)

	devAssert(
		isPlainObj(fieldMap),
		("%s fields must be an object with field names as keys or a function which returns such an object."):format(config.name)
	)

	return mapValue(fieldMap, function(fieldConfig, fieldName)
		devAssert(
			isPlainObj(fieldConfig),
			("%s.%s field config must be an object."):format(config.name, fieldName)
		)
		devAssert(
			fieldConfig.resolve == nil or typeof(fieldConfig.resolve) == "function",
			("%s.%s field resolver must be a function if "):format(config.name, fieldName) .. ("provided, but got: %s."):format(inspect(fieldConfig.resolve))
		)

		local argsConfig = (function()
			local _ref = fieldConfig.args

			if _ref == nil then
				_ref = {}
			end
			return _ref
		end)()

		devAssert(
			isPlainObj(argsConfig),
			("%s.%s args must be an object with argument names as keys."):format(config.name, fieldName)
		)

		local args = Array.map(objectEntries(argsConfig), function(entries)
			local argName, argConfig = entries[1], entries[2]

			return {
				name = argName,
				description = argConfig.description,
				type = argConfig.type,
				defaultValue = argConfig.defaultValue,
				deprecationReason = argConfig.deprecationReason,
				extensions = argConfig.extensions and toObjMap(argConfig.extensions),
				astNode = argConfig.astNode,
			}
		end)

		return {
			name = fieldName,
			description = fieldConfig.description,
			type = fieldConfig.type,
			args = args,
			resolve = fieldConfig.resolve,
			subscribe = fieldConfig.subscribe,
			deprecationReason = fieldConfig.deprecationReason,
			extensions = fieldConfig.extensions and toObjMap(fieldConfig.extensions),
			astNode = fieldConfig.astNode,
		}
	end)
end

function isPlainObj(obj: any)
	-- ROBLOX deviation: empty object is treated as an Array but in this case we want to allow it
	return isObjectLike(obj) and (not Array.isArray(obj) or next(obj) == nil)
end

function fieldsToFieldsConfig(fields)
	return mapValue(fields, function(field)
		return {
			description = field.description,
			type = field.type,
			args = argsToArgsConfig(field.args),
			resolve = field.resolve,
			subscribe = field.subscribe,
			deprecationReason = field.deprecationReason,
			extensions = field.extensions,
			astNode = field.astNode,
		}
	end)
end

--[[*
--  * @internal
--  *]]
function argsToArgsConfig(args)
	return keyValMap(args, function(arg)
		return arg.name
	end, function(arg)
		return {
			description = arg.description,
			type = arg.type,
			defaultValue = arg.defaultValue,
			deprecationReason = arg.deprecationReason,
			extensions = arg.extensions,
			astNode = arg.astNode,
		}
	end)
end

function isRequiredArgument(arg)
	return isNonNullType(arg.type) and arg.defaultValue == nil
end

-- /**
--  * Interface Type Definition
--  *
--  * When a field can return one of a heterogeneous set of types, a Interface type
--  * is used to describe what types are possible, what fields are in common across
--  * all types, as well as a function to determine which type is actually used
--  * when the field is resolved.
--  *
--  * Example:
--  *
--  *     const EntityType = new GraphQLInterfaceType({
--  *       name: 'Entity',
--  *       fields: {
--  *         name: { type: GraphQLString }
--  *       }
--  *     });
--  *
--  */
GraphQLInterfaceType = {}
GraphQLInterfaceType.__index = GraphQLInterfaceType

function GraphQLInterfaceType.new(config)
	local self = {}
	self.name = config.name
	self.description = config.description
	self.resolveType = config.resolveType
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	self._fields = function()
		return defineFieldMap(config)
	end
	self._interfaces = function()
		return defineInterfaces(config)
	end
	devAssert(typeof(config.name) == "string", "Must provide name.")
	devAssert(
		config.resolveType == nil or typeof(config.resolveType) == "function",
		("%s must provide \"resolveType\" as a function, " .. "but got: %s."):format(self.name, inspect(config.resolveType))
	)

	return setmetatable(self, GraphQLInterfaceType)
end

function GraphQLInterfaceType:getFields()
	if typeof(self._fields) == "function" then
		self._fields = self._fields()
	end
	return self._fields
end

function GraphQLInterfaceType:getInterfaces(): Array<any>
	if typeof(self._interfaces) == "function" then
		self._interfaces = self._interfaces()
	end
	return self._interfaces
end

function GraphQLInterfaceType:toConfig()
	return {
		name = self.name,
		description = self.description,
		interfaces = self:getInterfaces(),
		fields = fieldsToFieldsConfig(self:getFields()),
		resolveType = self.resolveType,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = self.extensionASTNodes or {},
	}
end

function GraphQLInterfaceType.__tostring(self)
	return self:toString()
end

function GraphQLInterfaceType.toString(self)
	return self.name
end

function GraphQLInterfaceType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLInterfaceType';
--   }
-- }

-- /**
--  * Union Type Definition
--  *
--  * When a field can return one of a heterogeneous set of types, a Union type
--  * is used to describe what types are possible as well as providing a function
--  * to determine which type is actually used when the field is resolved.
--  *
--  * Example:
--  *
--  *     const PetType = new GraphQLUnionType({
--  *       name: 'Pet',
--  *       types: [ DogType, CatType ],
--  *       resolveType(value) {
--  *         if (value instanceof Dog) {
--  *           return DogType;
--  *         }
--  *         if (value instanceof Cat) {
--  *           return CatType;
--  *         }
--  *       }
--  *     });
--  *
--  */
GraphQLUnionType = {}
GraphQLUnionType.__index = GraphQLUnionType

function GraphQLUnionType.new(config)
	local self = {}
	self.name = config.name
	self.description = config.description
	self.resolveType = config.resolveType
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	self._types = function()
		return defineTypes(config)
	end
	devAssert(typeof(config.name) == "string", "Must provide name.")
	devAssert(
		config.resolveType == nil or typeof(config.resolveType) == "function",
		("%s must provide \"resolveType\" as a function, " .. "but got: %s."):format(self.name, inspect(config.resolveType))
	)

	return setmetatable(self, GraphQLUnionType)
end

function GraphQLUnionType:getTypes(): Array<any>
	if typeof(self._types) == "function" then
		self._types = self._types()
	end
	return self._types
end

function GraphQLUnionType:toConfig()
	return {
		name = self.name,
		description = self.description,
		types = self:getTypes(),
		resolveType = self.resolveType,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = self.extensionASTNodes or {},
	}
end

function GraphQLUnionType.__tostring(self)
	return self:toString()
end

function GraphQLUnionType.toString(self)
	return self.name
end

function GraphQLUnionType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLUnionType';
--   }
-- }

function defineTypes(config)
	local types = resolveThunk(config.types)

	devAssert(
		Array.isArray(types),
		("Must provide Array of types or a function which returns such an array for Union %s."):format(config.name)
	)

	return types
end

-- /**
--  * Enum Type Definition
--  *
--  * Some leaf values of requests and input values are Enums. GraphQL serializes
--  * Enum values as strings, however internally Enums can be represented by any
--  * kind of type, often integers.
--  *
--  * Example:
--  *
--  *     const RGBType = new GraphQLEnumType({
--  *       name: 'RGB',
--  *       values: {
--  *         RED: { value: 0 },
--  *         GREEN: { value: 1 },
--  *         BLUE: { value: 2 }
--  *       }
--  *     });
--  *
--  * Note: If a value is not provided in a definition, the name of the enum value
--  * will be used as its internal value.
--  */
GraphQLEnumType = {}
GraphQLEnumType.__index = GraphQLEnumType

function GraphQLEnumType.new(config)
	local self = {}
	self.name = config.name
	self.description = config.description
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	self._values = defineEnumValues(self.name, config.values)
	self._valueLookup = {}
	Array.map(self._values, function(enumValue)
		self._valueLookup[enumValue.value] = enumValue
	end)
	self._nameLookup = keyMap(self._values, function(value)
		return value.name
	end)

	devAssert(typeof(config.name) == "string", "Must provide name.")

	return setmetatable(self, GraphQLEnumType)
end

function GraphQLEnumType:getValues(): Array<any>
	return self._values
end

function GraphQLEnumType:getValue(name: string)
	return self._nameLookup[name]
end

function GraphQLEnumType:serialize(outputValue)
	local enumValue = self._valueLookup[outputValue]
	if enumValue == nil then
		error(GraphQLError.new(("Enum \"%s\" cannot represent value: %s"):format(self.name, inspect(outputValue))))
	end
	return enumValue.name
end

function GraphQLEnumType:parseValue(inputValue)
	if typeof(inputValue) ~= "string" then
		local valueStr = inspect(inputValue)
		error(GraphQLError.new(("Enum \"%s\" cannot represent non-string value: %s." .. didYouMeanEnumValue(self, valueStr)):format(self.name, valueStr)))
	end

	local enumValue = self:getValue(inputValue)
	if enumValue == nil then
		error(GraphQLError.new(("Value \"%s\" does not exist in \"%s\" enum."):format(inputValue, self.name) .. didYouMeanEnumValue(self, inputValue)))
	end
	return enumValue.value
end

function GraphQLEnumType:parseLiteral(valueNode, _variables)
	-- Note: variables will be resolved to a value before calling this function.
	if valueNode.kind ~= Kind.ENUM then
		local valueStr = print_(valueNode)
		error(GraphQLError.new(
			("Enum \"%s\" cannot represent non-enum value: %s."):format(self.name, valueStr) .. didYouMeanEnumValue(self, valueStr),
			valueNode
		))
	end

	local enumValue = self:getValue(valueNode.value)
	if enumValue == nil then
		local valueStr = print_(valueNode)
		error(GraphQLError.new(
			("Value \"%s\" does not exist in \"%s\" enum."):format(valueStr, self.name) .. didYouMeanEnumValue(self, valueStr),
			valueNode
		))
	end
	return enumValue.value
end

function GraphQLEnumType:toConfig()
	local values = keyValMap(self:getValues(), function(value)
		return value.name
	end, function(value)
		return {
			description = value.description,
			value = value.value,
			deprecationReason = value.deprecationReason,
			extensions = value.extensions,
			astNode = value.astNode,
		}
	end)

	return {
		name = self.name,
		description = self.description,
		values = values,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = (function()
			local _ref = self.extensionASTNodes

			if _ref == nil then
				_ref = {}
			end
			return _ref
		end)(),
	}
end

function GraphQLEnumType.__tostring(self)
	return self:toString()
end

function GraphQLEnumType.toString(self)
	return self.name
end

function GraphQLEnumType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLEnumType';
--   }
-- }

function didYouMeanEnumValue(enumType, unknownValueStr: string): string
	local allNames = Array.map(enumType:getValues(), function(value)
		return value.name
	end)
	local suggestedValues = suggestionList(unknownValueStr, allNames)

	return didYouMean("the enum value", suggestedValues)
end

function defineEnumValues(typeName, valueMap)
	devAssert(
		isPlainObj(valueMap),
		("%s values must be an object with value names as keys."):format(tostring(typeName))
	)

	return Array.map(objectEntries(valueMap), function(entries)
		local valueName, valueConfig = entries[1], entries[2]

		devAssert(
			isPlainObj(valueConfig),
			("%s.%s must refer to an object with a \"value\" key "):format(tostring(typeName), valueName) .. ("representing an internal value but got: %s."):format(inspect(valueConfig))
		)

		return {
			name = valueName,
			description = valueConfig.description,
			value = (function()
				if valueConfig.value ~= nil then
					return valueConfig.value
				end

				return valueName
			end)(),
			deprecationReason = valueConfig.deprecationReason,
			extensions = valueConfig.extensions and toObjMap(valueConfig.extensions),
			astNode = valueConfig.astNode,
		}
	end)
end

-- /**
--  * Input Object Type Definition
--  *
--  * An input object defines a structured collection of fields which may be
--  * supplied to a field argument.
--  *
--  * Using `NonNull` will ensure that a value must be provided by the query
--  *
--  * Example:
--  *
--  *     const GeoPoint = new GraphQLInputObjectType({
--  *       name: 'GeoPoint',
--  *       fields: {
--  *         lat: { type: new GraphQLNonNull(GraphQLFloat) },
--  *         lon: { type: new GraphQLNonNull(GraphQLFloat) },
--  *         alt: { type: GraphQLFloat, defaultValue: 0 },
--  *       }
--  *     });
--  *
--  */
GraphQLInputObjectType = {}
GraphQLInputObjectType.__index = GraphQLInputObjectType

function GraphQLInputObjectType.new(config)
	local self = {}
	self.name = config.name
	self.description = config.description
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode
	self.extensionASTNodes = undefineIfEmpty(config.extensionASTNodes)

	self._fields = function()
		return defineInputFieldMap(config)
	end
	devAssert(typeof(config.name) == "string", "Must provide name.")
	return setmetatable(self, GraphQLInputObjectType)
end

function GraphQLInputObjectType:getFields()
	if typeof(self._fields) == "function" then
		self._fields = self._fields()
	end
	return self._fields
end

function GraphQLInputObjectType:toConfig()
	local fields = mapValue(self:getFields(), function(field)
		return {
			description = field.description,
			type = field.type,
			defaultValue = field.defaultValue,
			extensions = field.extensions,
			astNode = field.astNode,
		}
	end)

	return {
		name = self.name,
		description = self.description,
		fields = fields,
		extensions = self.extensions,
		astNode = self.astNode,
		extensionASTNodes = self.extensionASTNodes or {},
	}
end

function GraphQLInputObjectType.__tostring(self)
	return self:toString()
end

function GraphQLInputObjectType.toString(self)
	return self.name
end

function GraphQLInputObjectType.toJSON(self)
	return self:toString()
end

-- ROBLOX deviation: get [Symbol.toStringTag]() is not used within Lua
--   // $FlowFixMe[unsupported-syntax] Flow doesn't support computed properties yet
--   get [Symbol.toStringTag]() {
--     return 'GraphQLInputObjectType';
--   }
-- }

function defineInputFieldMap(config)
	local fieldMap = resolveThunk(config.fields)

	devAssert(
		isPlainObj(fieldMap),
		("%s fields must be an object with field names as keys or a function which returns such an object."):format(config.name)
	)

	return mapValue(fieldMap, function(fieldConfig, fieldName)
		devAssert(
			fieldConfig.resolve == nil,
			("%s.%s field has a resolve property, but Input Types cannot define resolvers."):format(config.name, fieldName)
		)

		return {
			name = fieldName,
			description = fieldConfig.description,
			type = fieldConfig.type,
			defaultValue = fieldConfig.defaultValue,
			deprecationReason = fieldConfig.deprecationReason,
			extensions = fieldConfig.extensions and toObjMap(fieldConfig.extensions),
			astNode = fieldConfig.astNode,
		}
	end)
end

function isRequiredInputField(field)
	return isNonNullType(field.type) and field.defaultValue == nil
end

-- TODO
local dummyClass = {}

function dummyClass.new()
	return {}
end

return {
	GraphQLList = GraphQLList,
	GraphQLNonNull = GraphQLNonNull,
	GraphQLScalarType = GraphQLScalarType,
	GraphQLObjectType = GraphQLObjectType,
	GraphQLInterfaceType = GraphQLInterfaceType,
	GraphQLUnionType = GraphQLUnionType,
	GraphQLEnumType = GraphQLEnumType,
	GraphQLInputObjectType = GraphQLInputObjectType,
	isType = isType,
	assertType = assertType,
	isScalarType = isScalarType,
	assertScalarType = assertScalarType,
	isObjectType = isObjectType,
	assertObjectType = assertObjectType,
	isInterfaceType = isInterfaceType,
	assertInterfaceType = assertInterfaceType,
	isUnionType = isUnionType,
	assertUnionType = assertUnionType,
	isEnumType = isEnumType,
	assertEnumType = assertEnumType,
	isInputObjectType = isInputObjectType,
	assertInputObjectType = assertInputObjectType,
	isListType = isListType,
	assertListType = assertListType,
	isNonNullType = isNonNullType,
	assertNonNullType = assertNonNullType,
	isInputType = isInputType,
	assertInputType = assertInputType,
	isOutputType = isOutputType,
	assertOutputType = assertOutputType,
	isLeafType = isLeafType,
	assertLeafType = assertLeafType,
	isCompositeType = isCompositeType,
	assertCompositeType = assertCompositeType,
	isAbstractType = isAbstractType,
	assertAbstractType = assertAbstractType,
	isWrappingType = isWrappingType,
	assertWrappingType = assertWrappingType,
	isNullableType = isNullableType,
	assertNullableType = assertNullableType,
	getNullableType = getNullableType,
	isNamedType = isNamedType,
	assertNamedType = assertNamedType,
	getNamedType = getNamedType,
	argsToArgsConfig = argsToArgsConfig,
	isRequiredArgument = isRequiredArgument,
	isRequiredInputField = isRequiredInputField,
	-- ROBLOX deviation: no distinction between undefined and null in Lua so we need to go around this with custom NULL like constant
	NULL = NULL,
}
