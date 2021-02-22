-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/execution/values.js

local srcWorkspace = script.Parent.Parent

local root = srcWorkspace.Parent
local LuauPolyfill = require(root.Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local NULL = require(srcWorkspace.luaUtils.null)
local isNillish = require(srcWorkspace.luaUtils.isNillish).isNillish

local keyMap = require(srcWorkspace.jsutils.keyMap).keyMap
local inspect = require(srcWorkspace.jsutils.inspect).inspect
local printPathArray = require(srcWorkspace.jsutils.printPathArray).printPathArray

local GraphQLError = require(srcWorkspace.error.GraphQLError).GraphQLError

local Kind = require(srcWorkspace.language.kinds).Kind
local print_ = require(srcWorkspace.language.printer).print

local definition = require(srcWorkspace.type.definition)
local isInputType = definition.isInputType
local isNonNullType = definition.isNonNullType

local typeFromAST = require(srcWorkspace.utilities.typeFromAST).typeFromAST
local valueFromAST = require(srcWorkspace.utilities.valueFromAST).valueFromAST
local coerceInputValue = require(srcWorkspace.utilities.coerceInputValue).coerceInputValue

-- ROBLOX deviation: predeclare functions
local getVariableValues
local coerceVariableValues
local getArgumentValues
local getDirectiveValues
local hasOwnProperty

--[[*
--  * Prepares an object map of variableValues of the correct type based on the
--  * provided variable definitions and arbitrary input. If the input cannot be
--  * parsed to match the variable definitions, a GraphQLError will be thrown.
--  *
--  * Note: The returned value is a plain Object with a prototype, since it is
--  * exposed to user code. Care should be taken to not pull values from the
--  * Object prototype.
--  *
--  * @internal
--  *]]
getVariableValues = function(schema, varDefNodes, inputs, options)
	local errors = {}
	local maxErrors
	if options ~= nil then
		maxErrors = options.maxErrors
	end

	local ok, result = pcall(function()
		local coerced = coerceVariableValues(schema, varDefNodes, inputs, function(error_)
			if maxErrors ~= nil and #errors >= maxErrors then
				error(GraphQLError.new("Too many errors processing variables, error limit reached. Execution aborted."))
			end
			table.insert(errors, error_)
		end)

		if #errors == 0 then
			return { coerced = coerced }
		end
		-- ROBLOX deviation: no implicit returns in Lua
		return nil
	end)

	-- ROBLOX deviation: return from inside try
	if ok and result ~= nil then
		return result
	end
	-- ROBLOX catch
	if not ok then
		table.insert(errors, result)
	end

	return { errors = errors }
end

function coerceVariableValues(schema, varDefNodes, inputs, onError)
	local coercedValues = {}
	for _, varDefNode in ipairs(varDefNodes) do
		local varName = varDefNode.variable.name.value
		local varType = typeFromAST(schema, varDefNode.type)
		if not isInputType(varType) then
			-- Must use input types for variables. This should be caught during
			-- validation, however is checked again here for safety.
			local varTypeStr = print_(varDefNode.type)
			onError(GraphQLError.new(
				("Variable \"$%s\" expected value of type \"%s\" which cannot be used as an input type."):format(varName, varTypeStr),
				varDefNode.type
			))
			continue
		end

		if not hasOwnProperty(inputs, varName) then
			if varDefNode.defaultValue then
				coercedValues[varName] = valueFromAST(varDefNode.defaultValue, varType)
			elseif isNonNullType(varType) then
				local varTypeStr = inspect(varType)
				onError(GraphQLError.new(
					("Variable \"$%s\" of required type \"%s\" was not provided."):format(varName, varTypeStr),
					varDefNode
				))
			end
			continue
		end

		local value = inputs[varName]
		if value == NULL and isNonNullType(varType) then
			local varTypeStr = inspect(varType)
			onError(GraphQLError.new(
				("Variable \"$%s\" of non-null type \"%s\" must not be null."):format(varName, varTypeStr),
				varDefNode
			))
			continue
		end

		coercedValues[varName] = coerceInputValue(
			value,
			varType,
			function(path, invalidValue, error_)
				local prefix = ("Variable \"$%s\" got invalid value "):format(varName) .. inspect(invalidValue)
				if #path > 0 then
					prefix ..= (" at \"%s%s\""):format(varName, printPathArray(path))
				end
				onError(GraphQLError.new(
					prefix .. "; " .. error_.message,
					varDefNode,
					nil,
					nil,
					nil,
					error_.originalError
				))
			end
		)
	end

	return coercedValues
end

--[[*
--  * Prepares an object map of argument values given a list of argument
--  * definitions and list of argument AST nodes.
--  *
--  * Note: The returned value is a plain Object with a prototype, since it is
--  * exposed to user code. Care should be taken to not pull values from the
--  * Object prototype.
--  *
--  * @internal
--  *]]
getArgumentValues = function(def, node, variableValues)
	local coercedValues = {}

	-- istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
	local argumentNodes = (function()
		local _ref = node.arguments

		if _ref == nil then
			_ref = {}
		end

		return _ref
	end)()
	local argNodeMap = keyMap(argumentNodes, function(arg)
		return arg.name.value
	end)

	for _, argDef in ipairs(def.args) do
		local name = argDef.name
		local argType = argDef.type
		local argumentNode = argNodeMap[name]

		if not argumentNode then
			if argDef.defaultValue ~= nil then
				coercedValues[name] = argDef.defaultValue
			elseif isNonNullType(argType) then
				error(GraphQLError.new(
					("Argument \"%s\" of required type \"%s\" "):format(name, inspect(argType)) .. "was not provided.",
					node
				))
			end
			continue
		end

		local valueNode = argumentNode.value
		local isNull = valueNode.kind == Kind.NULL

		if valueNode.kind == Kind.VARIABLE then
			local variableName = valueNode.name.value
			if variableValues == nil or not hasOwnProperty(variableValues, variableName) then
				if argDef.defaultValue ~= nil then
					coercedValues[name] = argDef.defaultValue
				elseif isNonNullType(argType) then
					error(GraphQLError.new(
						("Argument \"%s\" of required type \"%s\" "):format(name, inspect(argType)) .. ("was provided the variable \"$%s\" which was not provided a runtime value."):format(variableName),
						valueNode
					))
				end
				continue
			end
			isNull = isNillish(variableValues[variableName])
		end

		if isNull and isNonNullType(argType) then
			error(GraphQLError.new(
				("Argument \"%s\" of non-null type \"%s\" "):format(name, inspect(argType)) .. "must not be null.",
				valueNode
			))
		end

		local coercedValue = valueFromAST(valueNode, argType, variableValues)
		if coercedValue == nil then
			-- Note: ValuesOfCorrectTypeRule validation should catch this before
			-- execution. This is a runtime check to ensure execution does not
			-- continue with an invalid argument value.
			error(GraphQLError.new(
				("Argument \"%s\" has invalid value %s."):format(name, print_(valueNode)),
				valueNode
			))
		end
		coercedValues[name] = coercedValue
	end
	return coercedValues
end

--[[*
--  * Prepares an object map of argument values given a directive definition
--  * and a AST node which may contain directives. Optionally also accepts a map
--  * of variable values.
--  *
--  * If the directive does not exist on the node, returns undefined.
--  *
--  * Note: The returned value is a plain Object with a prototype, since it is
--  * exposed to user code. Care should be taken to not pull values from the
--  * Object prototype.
--  *]]
getDirectiveValues = function(directiveDef, node, variableValues)
	-- istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
	local directiveNode = node.directives and Array.find(node.directives, function(directive)
		return directive.name.value == directiveDef.name
	end)

	if directiveNode then
		return getArgumentValues(directiveDef, directiveNode, variableValues)
	end

	-- ROBLOX deviation: no implicit returns in Lua
	return nil
end

function hasOwnProperty(obj, prop)
	-- ROBLOX FIXME: not sure if this behavior is enough. There's no hasOwnProperty function in Lua
	return obj[prop] ~= nil
	-- return Object.prototype.hasOwnProperty.call(obj, prop)
end

return {
	getVariableValues = getVariableValues,
	getArgumentValues = getArgumentValues,
	getDirectiveValues = getDirectiveValues,
}
