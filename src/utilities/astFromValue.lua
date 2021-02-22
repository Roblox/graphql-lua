-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/astFromValue.js

local function NumberisFinite(value)
	return typeof(value) == "number" and value ~= math.huge and value == value
end

local srcWorkspace = script.Parent.Parent
local luaUtilsWorkspace = srcWorkspace.luaUtils

local objectValues = require(srcWorkspace.polyfills.objectValues).objectValues

local inspect = require(srcWorkspace.jsutils.inspect).inspect
local invariant = require(srcWorkspace.jsutils.invariant).invariant
local isObjectLike = require(srcWorkspace.jsutils.isObjectLike).isObjectLike
local isIteratableObject = require(srcWorkspace.jsutils.isIteratableObject).isIteratableObject

local Kind = require(srcWorkspace.language.kinds).Kind

local scalarsImport = require(srcWorkspace.type.scalars)
local GraphQLID = scalarsImport.GraphQLID
local definitionImport = require(srcWorkspace.type.definition)
local isLeafType = definitionImport.isLeafType
local isEnumType = definitionImport.isEnumType
local isInputObjectType = definitionImport.isInputObjectType
local isListType = definitionImport.isListType
local isNonNullType = definitionImport.isNonNullType

local _Number = require(srcWorkspace.Parent.Packages.LuauPolyfill).Number
local RegExp = require(srcWorkspace.Parent.Packages.LuauPolyfill).RegExp
local Error = require(luaUtilsWorkspace.Error)
local NULL = require(luaUtilsWorkspace.null)
local isNillishModule = require(luaUtilsWorkspace.isNillish)
local isNillish = isNillishModule.isNillish
local isNotNillish = isNillishModule.isNotNillish

-- ROBLOX deviation: predeclare local variables
local integerStringRegExp

--[[
 * Produces a GraphQL Value AST given a JavaScript object.
 * Function will match JavaScript/JSON values to GraphQL AST schema format
 * by using suggested GraphQLInputType. For example:
 *
 *     astFromValue("value", GraphQLString)
 *
 * A GraphQL type must be provided, which will be used to interpret different
 * JavaScript values.
 *
 * | JSON Value    | GraphQL Value        |
 * | ------------- | -------------------- |
 * | Object        | Input Object         |
 * | Array         | List                 |
 * | Boolean       | Boolean              |
 * | String        | String / Enum Value  |
 * | Number        | Int / Float          |
 * | Mixed         | Enum Value           |
 * | null          | NullValue            |
 *
 * ROBLOX deviation
 * passing nil will return nil
 * passing NULL will return Kind.NULL
 *]]
local function astFromValue(value, type_)
	if isNonNullType(type_) then
		local astValue = astFromValue(value, type_.ofType)

		if (astValue and astValue.kind) == Kind.NULL then
			return NULL
		end

		return astValue
	end

	-- ROBLOX devication: no difference between null and undefined
	-- only explicit null, not undefined, NaN
	if value == NULL then
		return {
			kind = Kind.NULL,
		}
	end

	-- undefined
	if value == nil then
		return NULL
	end

	-- Convert JavaScript array to GraphQL list. If the GraphQLType is a list, but
	-- the value is not an array, convert the value using the list's item type.
	if isListType(type_) then
		local itemType = type_.ofType

		if isIteratableObject(value) then
			local valuesNodes = {}
			-- Since we transpile for-of in loose mode it doesn't support iterators
			-- and it's required to first convert iteratable into array
			for _, item in pairs(value) do
				local itemNode = astFromValue(item, itemType)

				if isNotNillish(itemNode) then
					table.insert(valuesNodes, itemNode)
				end
			end

			return {
				kind = Kind.LIST,
				values = valuesNodes,
			}
		end

		return astFromValue(value, itemType)
	end
	-- Populate the fields of the input object by creating ASTs from each value
	-- in the JavaScript object according to the fields in the input type.
	if isInputObjectType(type_) then
		if not isObjectLike(value) then
			return NULL
		end

		local fieldNodes = {}

		for _, field in ipairs(objectValues(type_:getFields())) do
			local fieldValue = astFromValue(value[field.name], field.type)

			if isNotNillish(fieldValue) then
				table.insert(fieldNodes, {
					kind = Kind.OBJECT_FIELD,
					name = {
						kind = Kind.NAME,
						value = field.name,
					},
					value = fieldValue,
				})
			end
		end

		return {
			kind = Kind.OBJECT,
			fields = fieldNodes,
		}
	end

	-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
	if isLeafType(type_) then
		-- Since value is an internally represented value, it must be serialized
		-- to an externally represented value before converting into an AST.
		local serialized = type_:serialize(value)
		if isNillish(serialized) then
			return NULL
		end

		-- Others serialize based on their corresponding JavaScript scalar types.
		if typeof(serialized) == "boolean" then
			return {
				kind = Kind.BOOLEAN,
				value = serialized,
			}
		end

		-- JavaScript numbers can be Int or Float values.
		if typeof(serialized) == "number" and NumberisFinite(serialized) then
			local stringNum = tostring(serialized)

			return (function()
				if integerStringRegExp:test(stringNum) then
					return {
						kind = Kind.INT,
						value = stringNum,
					}
				end

				return {
					kind = Kind.FLOAT,
					value = stringNum,
				}
			end)()
		end
		if typeof(serialized) == "string" then
			-- Enum types use Enum literals.
			if isEnumType(type_) then
				return {
					kind = Kind.ENUM,
					value = serialized,
				}
			end

			-- ID types can use Int literals.
			if type_ == GraphQLID and integerStringRegExp:test(serialized) then
				return {
					kind = Kind.INT,
					value = serialized,
				}
			end

			return {
				kind = Kind.STRING,
				value = serialized,
			}
		end

		-- ROBLOX deviation: no TypeError in Lua
		error(Error.new(("Cannot convert value to AST: %s."):format(inspect(serialized))))
	end

	-- istanbul ignore next (Not reachable. All possible input types have been considered)
	invariant(false, "Unexpected input type: " + inspect(type_))
	return
end

--[[*
--  * IntValue:
--  *   - NegativeSign? 0
--  *   - NegativeSign? NonZeroDigit ( Digit+ )?
--  *]]
integerStringRegExp = RegExp("^-?(?:0|[1-9][0-9]*)$")

return {
	astFromValue = astFromValue,
	NULL = NULL
}
