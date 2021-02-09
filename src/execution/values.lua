-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/aa650618426a301e3f0f61ead3adcd755055a627/src/execution/values.js
local srcWorkspace = script.Parent.Parent
local root = srcWorkspace.Parent
local LuauPolyfill = require(root.Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

local keyMap = require(srcWorkspace.jsutils.keyMap).keyMap
local inspect = require(srcWorkspace.jsutils.inspect).inspect
local printPathArray = require(srcWorkspace.jsutils.printPathArray).printArrayPath
local GraphQLError = require(srcWorkspace.error.GraphQLError).GraphQLError
local Kind = require(srcWorkspace.language.kinds).Kind
local print_ = require(srcWorkspace.language.printer).print
local definition = require(srcWorkspace.type.definition)
local isInputType = definition.isInputType
local isNonNullType = definition.isNonNullType
local typeFromAST = require(srcWorkspace.utilities.typeFromAST).typeFromAST
local valueFromAST = require(srcWorkspace.utilities.valueFromAST).valueFromAST
-- ROBLOX FIXME: use the real coerceInputValue once that branch is merged
-- local coerceInputValue = require(srcWorkspace.utilities.coerceInputValue).coerceInputValue
local function coerceInputValue(value, _, __)
 return value
end
local getVariableValues, getArgumentValues, getDirectiveValues, coerceVariableValues

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
			return { coerced }
		end
		-- ROBLOX deviatin: no implicit returns in Lua
		return nil
	end)

	-- ROBLOX deviation: return from inside try
	if ok then
		if #errors == 0 then
			return { result }
		end
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
			local varTypeStr = print_(varDefNode.type)

			onError(GraphQLError.new(
				("Variable \"$%s\" expected value of type \"%s\" which cannot be used as an input type."):format(varName, varTypeStr),
				varDefNode.type
			))
		end
		if not Object.hasOwnProperty(inputs, varName) then
			if varDefNode.defaultValue then
				coercedValues[varName] = valueFromAST(varDefNode.defaultValue, varType)
			elseif isNonNullType(varType) then
				local varTypeStr = inspect(varType)

				onError(GraphQLError.new(
					("Variable \"$%s\" of required type \"%s\" was not provided."):format(varName, varTypeStr),
					varDefNode
				))
			end
		end

		local value = inputs[varName]

		if value == nil and isNonNullType(varType) then
			local varTypeStr = inspect(varType)

			onError(GraphQLError.new(
				("Variable \"$%s\" of non-null type \"%s\" must not be null."):format(varName, varTypeStr),
				varDefNode
			))
		end

		coercedValues[varName] = coerceInputValue(value, varType, function(path, invalidValue, error_)
			local prefix = ("Variable \"$%s\" got invalid value "):format(varName) + inspect(invalidValue)

			if path.length > 0 then
				prefix = prefix + (" at \"%s%s\""):format(varName, printPathArray(path))
			end

			onError(GraphQLError.new(prefix + "; " + error_.message, varDefNode, nil, nil, nil, error_.originalError))
		end)
	end

	return coercedValues
end

getArgumentValues = function(def, node, variableValues)
	local coercedValues = {}
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
					("Argument \"%s\" of required type \"%s\" "):format(name, inspect(argType)) + "was not provided.",
					node
				))
			end
		end

		local valueNode = argumentNode.value
		local isNull = valueNode.kind == Kind.NULL

		if valueNode.kind == Kind.VARIABLE then
			local variableName = valueNode.name.value

			if variableValues == nil or not Object.hasOwnProperty(variableValues, variableName) then
				if argDef.defaultValue ~= nil then
					coercedValues[name] = argDef.defaultValue
				elseif isNonNullType(argType) then
					error(GraphQLError.new(
						("Argument \"%s\" of required type \"%s\" "):format(name, inspect(argType)) + ("was provided the variable \"$%s\" which was not provided a runtime value."):format(variableName),
						valueNode
					))
				end
			end

			isNull = variableValues[variableName] == nil
		end
		if isNull and isNonNullType(argType) then
			error(GraphQLError.new(
				("Argument \"%s\" of non-null type \"%s\" "):format(name, inspect(argType)) + "must not be null.",
				valueNode
			))
		end

		local coercedValue = valueFromAST(valueNode, argType, variableValues)

		if coercedValue == nil then
			error(GraphQLError.new(
				("Argument \"%s\" has invalid value %s."):format(name, print_(valueNode)),
				valueNode
			))
		end

		coercedValues[name] = coercedValue
	end

	return coercedValues
end

getDirectiveValues = function(directiveDef, node, variableValues)
	local directiveNode
	if node.directives then
		directiveNode = Array.find(node.directives, function(directive)
			return directive.name.value == directiveDef.name
		end)
	end

	if directiveNode then
		return getArgumentValues(directiveDef, directiveNode, variableValues)
	end

	-- ROBLOX deviation: no implicit returns in Lua
	return nil
end

return {
	getDirectiveValues = getDirectiveValues,
	getVariableValues = getVariableValues,
}
