-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/printSchema.js

local srcWorkspace = script.Parent.Parent
local rootWorkspace = srcWorkspace.Parent
local PackagesWorkspace = rootWorkspace

local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean

local inspect = require(script.Parent.Parent.jsutils.inspect).inspect
local invariant = require(script.Parent.Parent.jsutils.invariant).invariant

local print_ = require(script.Parent.Parent.language.printer).print
local printBlockString = require(script.Parent.Parent.language.blockString).printBlockString

local isIntrospectionType = require(script.Parent.Parent.type.introspection).isIntrospectionType
local GraphQLString = require(script.Parent.Parent.type.scalars).GraphQLString
local isSpecifiedScalarType = require(script.Parent.Parent.type.scalars).isSpecifiedScalarType
local DirectivesModules = require(script.Parent.Parent.type.directives)
local DEFAULT_DEPRECATION_REASON = DirectivesModules.DEFAULT_DEPRECATION_REASON
local isSpecifiedDirective = DirectivesModules.isSpecifiedDirective
local DefinitionModule = require(script.Parent.Parent.type.definition)
local isScalarType = DefinitionModule.isScalarType
local isObjectType = DefinitionModule.isObjectType
local isInterfaceType = DefinitionModule.isInterfaceType
local isUnionType = DefinitionModule.isUnionType
local isEnumType = DefinitionModule.isEnumType
local isInputObjectType = DefinitionModule.isInputObjectType

local astFromValue = require(script.Parent.astFromValue).astFromValue
local NULL = require(script.Parent.astFromValue).NULL
local isNillishModule = require(script.Parent.Parent.luaUtils.isNillish)
local isNillish = isNillishModule.isNillish
local isNotNillish = isNillishModule.isNotNillish

-- ROBLOX deviation: predeclare types
local printScalar, printDescription, printFilteredSchema, isDefinedType, printSchemaDefinition, printDirective, printType, isSchemaOfCommonNames, printObject, printFields, printArgs, printInputValue, printDeprecated, printBlock, printInterface, printUnion, printEnum, printInputObject, printSpecifiedByUrl

local function printSchema(schema)
	return printFilteredSchema(schema, function(n)
		return not isSpecifiedDirective(n)
	end, isDefinedType)
end

local function printIntrospectionSchema(schema)
	return printFilteredSchema(schema, isSpecifiedDirective, isIntrospectionType)
end

function isDefinedType(type_)
	return not isSpecifiedScalarType(type_) and not isIntrospectionType(type_)
end

function printFilteredSchema(schema: any, directiveFilter: (any) -> boolean, typeFilter: (any) -> boolean): string
	local directives = Array.filter(schema:getDirectives(), directiveFilter)
	-- ROBLOX deviation: use Map type
	local types = Array.filter(schema:getTypeMap():values(), typeFilter)

	local combined = Array.concat(
		{
			printSchemaDefinition(schema),
		},
		Array.map(directives, function(directive)
			return printDirective(directive)
		end),
		Array.map(types, function(type_)
			return printType(type_)
		end)
	)

	local filtered = Array.filter(combined, function(el)
		return Boolean.toJSBoolean(el)
	end)

	return Array.join(filtered, "\n\n") .. "\n"
end

function printSchemaDefinition(schema)
	if isNillish(schema.description) and isSchemaOfCommonNames(schema) then
		return
	end

	local operationTypes = {}
	local queryType = schema:getQueryType()

	if isNotNillish(queryType) then
		table.insert(operationTypes, ("  query: %s"):format(queryType.name))
	end

	local mutationType = schema:getMutationType()

	if isNotNillish(mutationType) then
		table.insert(operationTypes, ("  mutation: %s"):format(mutationType.name))
	end

	local subscriptionType = schema:getSubscriptionType()

	if isNotNillish(subscriptionType) then
		table.insert(operationTypes, ("  subscription: %s"):format(subscriptionType.name))
	end

	return printDescription(schema) .. ("schema {\n%s\n}"):format(Array.join(operationTypes, "\n"))
end

--[[
 * GraphQL schema define root types for each type of operation. These types are
 * the same as any other type and can be named in any manner, however there is
 * a common naming convention:
 *
 *   schema {
 *     query: Query
 *     mutation: Mutation
 *   }
 *
 * When using this naming convention, the schema description can be omitted.
 *]]
function isSchemaOfCommonNames(schema): boolean
	local queryType = schema:getQueryType()

	if isNotNillish(queryType) and queryType.name ~= "Query" then
		return false
	end

	local mutationType = schema:getMutationType()

	if isNotNillish(mutationType) and mutationType.name ~= "Mutation" then
		return false
	end

	local subscriptionType = schema:getSubscriptionType()

	if isNotNillish(subscriptionType) and subscriptionType.name ~= "Subscription" then
		return false
	end

	return true
end

function printType(type_)
	if isScalarType(type_) then
		return printScalar(type_)
	end
	if isObjectType(type_) then
		return printObject(type_)
	end
	if isInterfaceType(type_) then
		return printInterface(type_)
	end
	if isUnionType(type_) then
		return printUnion(type_)
	end
	if isEnumType(type_) then
		return printEnum(type_)
	end
	-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
	if isInputObjectType(type_) then
		return printInputObject(type_)
	end

	-- istanbul ignore next (Not reachable. All possible types have been considered)
	invariant(false, "Unexpected type: " .. inspect(type_))
	return -- ROBLOX deviation: no implicit returns
end

function printScalar(type_)
	return printDescription(type_) .. ("scalar %s"):format(type_.name) .. printSpecifiedByUrl(type_)
end

local function printImplementedInterfaces(type_)
	local interfaces = type_:getInterfaces()

	return (function()
		if #interfaces > 0 then
			return " implements "
				.. Array.join(
					Array.map(interfaces, function(i)
						return i.name
					end),
					" & "
				)
		end

		return ""
	end)()
end

function printObject(type_): string
	return printDescription(type_)
		.. ("type %s"):format(type_.name)
		.. printImplementedInterfaces(type_)
		.. printFields(type_)
end

function printInterface(type_): string
	return printDescription(type_)
		.. ("interface %s"):format(type_.name)
		.. printImplementedInterfaces(type_)
		.. printFields(type_)
end

function printUnion(type_): string
	local types = type_:getTypes()
	local possibleTypes = (function()
		if #types > 0 then
			return " = " .. Array.join(types, " | ")
		end

		return ""
	end)()

	return printDescription(type_) .. "union " .. type_.name .. possibleTypes
end

function printEnum(type_): string
	local values = Array.map(type_:getValues(), function(value, i)
		return printDescription(value, "  ", i == 1) .. "  " .. value.name .. printDeprecated(value.deprecationReason)
	end)

	return printDescription(type_) .. ("enum %s"):format(type_.name) .. printBlock(values)
end

function printInputObject(type_)
	-- ROBLOX deviation: use Map
	local fields = Array.map(type_:getFields():values(), function(f, i)
		return printDescription(f, "  ", i == 1) .. "  " .. printInputValue(f)
	end)

	return printDescription(type_) .. ("input %s"):format(type_.name) .. printBlock(fields)
end

function printFields(type_): string
	-- ROBLOX deviation: use Map
	local fields = Array.map(type_:getFields():values(), function(f, i)
		return printDescription(f, "  ", i == 1)
			.. "  "
			.. f.name
			.. printArgs(f.args, "  ")
			.. ": "
			.. tostring(f.type)
			.. printDeprecated(f.deprecationReason)
	end)

	return printBlock(fields)
end

function printBlock(items)
	return (function()
		if #items ~= 0 then
			return " {\n" .. Array.join(items, "\n") .. "\n}"
		end

		return ""
	end)()
end

function printArgs(args, indentation_: string?)
	local indentation = (function()
		if indentation_ ~= nil then
			return indentation_
		end

		return ""
	end)()

	if #args == 0 then
		return ""
	end

	-- If every arg does not have a description, print them on one line.
	if
		Array.every(args, function(arg)
			-- ROBLOX deviation: execution can return NULL - so we must check for null or nil
			return isNillish(arg.description)
		end)
	then
		return "(" .. Array.join(Array.map(args, printInputValue), ", ") .. ")"
	end

	return "(\n"
		.. Array.join(
			Array.map(args, function(arg, i)
				return printDescription(arg, "  " .. indentation, i == 1) .. "  " .. indentation .. printInputValue(arg)
			end),
			"\n"
		)
		.. "\n"
		.. indentation
		.. ")"
end

function printInputValue(arg): string
	local defaultAST = astFromValue(arg.defaultValue, arg.type)
	local argDecl = arg.name .. ": " .. tostring(arg.type)

	if isNotNillish(defaultAST) then
		argDecl ..= (" = %s"):format(print_(defaultAST))
	end

	return argDecl .. printDeprecated(arg.deprecationReason)
end

function printDirective(directive)
	return printDescription(directive)
		.. "directive @"
		.. directive.name
		.. printArgs(directive.args)
		.. (function()
			if directive.isRepeatable then
				return " repeatable"
			end

			return ""
		end)()
		.. " on "
		.. Array.join(directive.locations, " | ")
end

function printDeprecated(reason: string?): string
	if isNillish(reason) then
		return ""
	end

	local reasonAST = astFromValue(reason, GraphQLString)

	if reasonAST and reason ~= DEFAULT_DEPRECATION_REASON then
		return " @deprecated(reason: " .. print_(reasonAST) .. ")"
	end

	return " @deprecated"
end

function printSpecifiedByUrl(scalar): string
	if isNillish(scalar.specifiedByUrl) then
		return ""
	end

	local url = scalar.specifiedByUrl
	local urlAST = astFromValue(url, GraphQLString)

	invariant(urlAST, "Unexpected null value returned from `astFromValue` for specifiedByUrl")

	return " @specifiedBy(url: " .. print_(urlAST) .. ")"
end

function printDescription(def, indentation_: string?, firstInBlock_: boolean?)
	-- ROBLOX deviation: handle default paramters
	local indentation = (function()
		if indentation_ ~= nil then
			return indentation_
		end
		return ""
	end)()

	local firstInBlock = (function()
		if firstInBlock_ ~= nil then
			return firstInBlock_
		end
		return true
	end)()

	local description = def.description

	if isNillish(description) then
		return ""
	end

	local preferMultipleLines = string.len(description) > 70
	local blockString = printBlockString(description, "", preferMultipleLines)
	local prefix = (function()
		if indentation and not firstInBlock then
			return "\n" .. indentation
		end

		return indentation
	end)()

	return prefix .. blockString:gsub("\n", "\n" .. indentation) .. "\n"
end

return {
	printSchema = printSchema,
	printIntrospectionSchema = printIntrospectionSchema,
	printType = printType,
	NULL = NULL, -- ROBLOX deviation: differentiate null and undefined
}
