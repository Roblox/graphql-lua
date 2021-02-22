-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/coerceInputValue.js

local srcWorkspace = script.Parent.Parent
local rootWorkspace = srcWorkspace.Parent
local jsutilsWorkspace = srcWorkspace.jsutils
local luaUtilsWorkspace = srcWorkspace.luaUtils

local LuauPolyfill = require(rootWorkspace.Packages.LuauPolyfill)

local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local inspect = require(jsutilsWorkspace.inspect).inspect
local invariant = require(jsutilsWorkspace.invariant).invariant
local didYouMean = require(jsutilsWorkspace.didYouMean).didYouMean
local isObjectLike = require(jsutilsWorkspace.isObjectLike).isObjectLike
local suggestionList = require(jsutilsWorkspace.suggestionList).suggestionList
local printPathArray = require(jsutilsWorkspace.printPathArray).printPathArray
local addPath = require(jsutilsWorkspace.Path).addPath
local instanceOf = require(jsutilsWorkspace.instanceOf)
local NULL = require(luaUtilsWorkspace.null)
local isNillishModule = require(luaUtilsWorkspace.isNillish)
local isNillish = isNillishModule.isNillish
local isNotNillish = isNillishModule.isNotNillish

local pathToArray = require(jsutilsWorkspace.Path).pathToArray
local isIteratableObject = require(jsutilsWorkspace.isIteratableObject).isIteratableObject
local GraphQLError = require(srcWorkspace.error.GraphQLError).GraphQLError
local definition = require(srcWorkspace.type.definition)
local objectValues = require(srcWorkspace.polyfills.objectValues).objectValues

local isLeafType = definition.isLeafType
local isInputObjectType = definition.isInputObjectType
local isListType = definition.isListType
local isNonNullType = definition.isNonNullType

local coerceInputValueImpl
local defaultOnError

--[[**
	* Coerces a JavaScript value given a GraphQL Input Type_.
	*]]
local function coerceInputValue(inputValue, type_, onError_)
	local onError = onError_ or defaultOnError
	return coerceInputValueImpl(inputValue, type_, onError)
end

function defaultOnError(path, invalidValue, error_)
	local errorPrefix = "Invalid value " .. inspect(invalidValue)
	if #path > 0 then
		errorPrefix = errorPrefix .. " at \"value" .. printPathArray(path) .. "\""
	end
	error_.message = errorPrefix .. ": " .. error_.message
	error(error_)
end

function coerceInputValueImpl(inputValue, type_, onError, path)
	if isNonNullType(type_) then
		if isNotNillish(inputValue) then
			return coerceInputValueImpl(inputValue, type_.ofType, onError, path)
		end
		onError(
			pathToArray(path),
			inputValue,
			GraphQLError.new("Expected non-nullable type \"" .. inspect(type_) .. "\" not to be null.")
		)
		return
	end

	if isNillish(inputValue) then
		-- Explicitly return the value null.
		return NULL
	end

	if isListType(type_) then
		local itemType = type_.ofType
		if isIteratableObject(inputValue) then
			return Array.from(inputValue, function(itemValue, index)
				local itemPath = addPath(path, index, nil)
				return coerceInputValueImpl(itemValue, itemType, onError, itemPath)
			end)
		end

		-- Lists accept a non-list value as a list of one.
		return { coerceInputValueImpl(inputValue, itemType, onError, path) }
	end

	if isInputObjectType(type_) then
		if not isObjectLike(inputValue) then
			onError(
				pathToArray(path),
				inputValue,
				GraphQLError.new("Expected type \"" .. type_.name .. "\" to be an object.")
			)
			return
		end

		local coercedValue = {}
		local fieldDefs = type_:getFields()

		for _, field in ipairs(objectValues(fieldDefs)) do
			local fieldValue = inputValue[field.name]
			if fieldValue == nil then
				if field.defaultValue ~= nil then
					coercedValue[field.name] = field.defaultValue
				elseif isNonNullType(field.type) then
					local typeStr = inspect(field.type)
					onError(
						pathToArray(path),
						inputValue,
						GraphQLError.new("Field \"" .. field.name .. "\" of required type \"" .. typeStr .. "\" was not provided.")
					)
				end
				continue
			end

			coercedValue[field.name] = coerceInputValueImpl(
				fieldValue,
				field.type,
				onError,
				addPath(path, field.name, type_.name)
			)

		end

		-- Ensure every provided field is defined
		for _, fieldName in ipairs(Object.keys(inputValue)) do
			if not fieldDefs[fieldName] then
				local suggestions = suggestionList(fieldName, Object.keys(type_:getFields()))
				onError(
					pathToArray(path),
					inputValue,
					GraphQLError.new(("Field \"%s\" is not defined by type \"%s\".%s"):format(fieldName, type_.name, didYouMean(suggestions)))
				)
			end
		end
		return coercedValue

	end

	-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
	if isLeafType(type_) then
		local parseResult

		-- Scalars and Enums determine if a input value is valid via parseValue(),
		-- which can throw to indicate failure. If it throws, maintain a reference
		-- to the original error.
		local ok, thrownError = pcall(function()
			parseResult = type_:parseValue(inputValue)
		end)

		if not ok then
			if instanceOf(thrownError, GraphQLError) then
				onError(pathToArray(path), inputValue, thrownError)
			else
				onError(
					pathToArray(path),
					inputValue,
					GraphQLError.new(
						"Expected type \"" .. type_.name .. "\". " .. thrownError.message,
						nil,
						nil,
						nil,
						nil,
						thrownError
					)
				)
			end
			return
		end

		if parseResult == nil then
			onError(
				pathToArray(path),
				inputValue,
				GraphQLError.new(("Expected type \"%s\"."):format(type_.name))
			)
		end
		return parseResult
	end

	-- istanbul ignore next (Not reachable. All possible input types have been considered)
	invariant(false, "Unexpected input type: " .. inspect(type_))
	return
end

return {
	coerceInputValue = coerceInputValue,
}
