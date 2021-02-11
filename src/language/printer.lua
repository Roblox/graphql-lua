-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/printer.js

type Array<T> = { [number]: T }
local srcWorkspace = script.Parent.Parent
local root = srcWorkspace.Parent

local visit = require(script.Parent.visitor).visit
local printBlockString = require(script.Parent.blockString).printBlockString

local Array = require(root.Packages.LuauPolyfill).Array
local UtilArray = require(srcWorkspace.luaUtils.Array)

local HttpService = game:GetService("HttpService")

-- deviation: pre-declare functions
local printDocASTReducer
local addDescription
local join
local block
local wrap
local indent
local isMultiline
local hasMultilineItems

--[[**
--  * Converts an AST into a string, using one set of reasonable
--  * formatting rules.
--  *]]
local function print_(ast): string
	return visit(ast, { leave = printDocASTReducer })
end

local MAX_LINE_LENGTH = 80

-- ROBLOX deviation: addDescription needs to be declared above printDocASTReducer
-- addDescription is called when declaring printDocASTReducer and Lua doesn't hoist functions
function addDescription(cb)
	return function(_self, node)
		return join({ node.description, cb(node) }, "\n")
	end
end

-- TODO: provide better type coverage in future
printDocASTReducer = {
	Name = function(_self, node)
		return node.value
	end,

	Variable = function(_self, node)
		return "$" .. node.name
	end,

	-- Document

	Document = function(_self, node)
		return join(node.definitions, "\n\n") .. "\n"
	end,

	OperationDefinition = function(_self, node)
		local op = node.operation
		local name = node.name
		local varDefs = wrap("(", join(node.variableDefinitions, ", "), ")")
		local directives = join(node.directives, " ")
		local selectionSet = node.selectionSet
		-- Anonymous queries with no directives or variable definitions can use
		-- the query short form.
		if
			not (name and name ~= "")
			and not (directives and directives ~= "")
			and not (varDefs and varDefs ~= "")
			and op == "query"
		then
			return selectionSet
		else
			return join({ op, join({ name, varDefs }), directives, selectionSet }, " ")
		end
	end,

	VariableDefinition = function(_self, node)
		local variable = node.variable
		local type_ = node.type
		local defaultValue = node.defaultValue
		local directives = node.directives
		return variable .. ": " .. type_ .. wrap(" = ", defaultValue) .. wrap(" ", join(directives, " "))
	end,

	SelectionSet = function(_self, node)
		return block(node.selections)
	end,

	Field = function(_self, node)
		local alias = node.alias
		local name = node.name
		local args = node.arguments
		local directives = node.directives
		local selectionSet = node.selectionSet
		local prefix = wrap("", alias, ": ") .. tostring(name)
		local argsLine = prefix .. wrap("(", join(args, ", "), ")")

		if utf8.len(argsLine) > MAX_LINE_LENGTH then
			argsLine = prefix .. wrap("(\n", indent(join(args, "\n")), "\n)")
		end

		return join({ argsLine, join(directives, " "), selectionSet }, " ")
	end,

	Argument = function(_self, node)
		local name = node.name
		local value = node.value
		return name .. ": " .. value
	end,

	-- Fragments

	FragmentSpread = function(_self, node)
		local name = node.name
		local directives = node.directives
		return "..." .. name .. wrap(" ", join(directives, " "))
	end,

	InlineFragment = function(_self, node)
		local typeCondition = node.typeCondition
		local directives = node.directives
		local selectionSet = node.selectionSet
		return join(
			{ "...", wrap("on ", typeCondition), join(directives, " "), selectionSet },
			" "
		)
	end,

	FragmentDefinition = function(_self, node)
		local name = node.name
		local typeCondition = node.typeCondition
		local variableDefinitions = node.variableDefinitions
		local directives = node.directives
		local selectionSet = node.selectionSet
		-- Note: fragment variable definitions are experimental and may be changed
		-- or removed in the future.
		-- ROBLOX deviation: inlined output for formatting
		local output = "fragment "
			.. name
			.. wrap("(", join(variableDefinitions, ", "), ")")
			.. " "
			.. "on "
			.. typeCondition
			.. " "
			.. wrap("", join(directives, " "), " ")
			.. selectionSet
		return output
	end,

	-- Value

	IntValue = function(_self, node)
		local value = node.value
		return value
	end,
	FloatValue = function(_self, node)
		local value = node.value
		return value
	end,
	StringValue = function(_self, node, key)
		local value = node.value
		local isBlockingString = node.block
		if isBlockingString then
			return printBlockString(
				value,
				(function()
					if key == "description" then
						return ""
					else
						return "  "
					end
				end)()
			)
		else
			return HttpService:JSONEncode(value)
		end
	end,
	BooleanValue = function(_self, node)
		local value = node.value
		if value then
			return "true"
		else
			return "false"
		end
	end,
	NullValue = function(_self)
		return "null"
	end,
	EnumValue = function(_self, node)
		local value = node.value
		return value
	end,
	ListValue = function(_self, node)
		local values = node.values
		return "[" .. join(values, ", ") .. "]"
	end,
	ObjectValue = function(_self, node)
		local fields = node.fields
		return "{" .. join(fields, ", ") .. "}"
	end,
	ObjectField = function(_self, node)
		local name = node.name
		local value = node.value
		return name .. ": " .. value
	end,

	-- Directive

	Directive = function(_self, node)
		local name = node.name
		local args = node.arguments
		return "@" .. name .. wrap("(", join(args, ", "), ")")
	end,

	-- Type

	NamedType = function(_self, node)
		local name = node.name
		return name
	end,
	ListType = function(_self, node)
		local type_ = node.type
		return "[" .. type_ .. "]"
	end,
	NonNullType = function(_self, node)
		local type_ = node.type
		return type_ .. "!"
	end,

	-- Type System Definitions

	SchemaDefinition = addDescription(function(node)
		local directives = node.directives
		local operationTypes = node.operationTypes
		return join({ "schema", join(directives, " "), block(operationTypes) }, " ")
	end),

	OperationTypeDefinition = function(_self, node)
		local operation = node.operation
		local type_ = node.type
		return operation .. ": " .. type_
	end,

	ScalarTypeDefinition = addDescription(function(node)
		local name = node.name
		local directives = node.directives
		return join({ "scalar", name, join(directives, " ") }, " ")
	end),

	ObjectTypeDefinition = addDescription(function(node)
		local name = node.name
		local interfaces = node.interfaces
		local directives = node.directives
		local fields = node.fields
		return join(
			{
				"type",
				name,
				wrap("implements ", join(interfaces, " & ")),
				join(directives, " "),
				block(fields),
			},
			" "
		)
	end),

	FieldDefinition = addDescription(function(node)
		local name = node.name
		local args = node.arguments
		local type_ = node.type
		local directives = node.directives
		return name .. (function()
			if hasMultilineItems(args) then
				return wrap("(\n", indent(join(args, "\n")), "\n)")
			else
				return wrap("(", join(args, ", "), ")")
			end
		end)() .. ": " .. type_ .. wrap(" ", join(directives, " "))
	end),

	InputValueDefinition = addDescription(function(node)
		local name = node.name
		local type_ = node.type
		local defaultValue = node.defaultValue
		local directives = node.directives
		return join(
			{ name .. ": " .. type_, wrap("= ", defaultValue), join(directives, " ") },
			" "
		)
	end),

	InterfaceTypeDefinition = addDescription(function(node)
		local name = node.name
		local interfaces = node.interfaces
		local directives = node.directives
		local fields = node.fields
		return join(
			{
				"interface",
				name,
				wrap("implements ", join(interfaces, " & ")),
				join(directives, " "),
				block(fields),
			},
			" "
		)
	end),

	UnionTypeDefinition = addDescription(function(node)
		local name = node.name
		local directives = node.directives
		local types = node.types
		return join(
			{
				"union",
				name,
				join(directives, " "),
				(function()
					if types and #types ~= 0 then
						return "= " .. join(types, " | ")
					else
						return ""
					end
				end)(),
			},
			" "
		)
	end),

	EnumTypeDefinition = addDescription(function(node)
		local name = node.name
		local directives = node.directives
		local values = node.values
		return join({ "enum", name, join(directives, " "), block(values) }, " ")
	end),

	EnumValueDefinition = addDescription(function(node)
		local name = node.name
		local directives = node.directives
		return join({ name, join(directives, " ") }, " ")
	end),

	InputObjectTypeDefinition = addDescription(function(node)
		local name = node.name
		local directives = node.directives
		local fields = node.fields
		return join({ "input", name, join(directives, " "), block(fields) }, " ")
	end),

	DirectiveDefinition = addDescription(function(node)
		local name = node.name
		local args = node.arguments
		local repeatable = node.repeatable
		local locations = node.locations
		return "directive @" .. name .. (function()
			if hasMultilineItems(args) then
				return wrap("(\n", indent(join(args, "\n")), "\n)")
			else
				return wrap("(", join(args, ", "), ")")
			end
		end)() .. (function()
			if repeatable then
				return " repeatable"
			else
				return ""
			end
		end)() .. " on " .. join(locations, " | ")
	end),

	SchemaExtension = function(_self, node)
		local directives = node.directives
		local operationTypes = node.operationTypes
		return join({ "extend schema", join(directives, " "), block(operationTypes) }, " ")
	end,

	ScalarTypeExtension = function(_self, node)
		local name = node.name
		local directives = node.directives
		return join({ "extend scalar", name, join(directives, " ") }, " ")
	end,

	ObjectTypeExtension = function(_self, node)
		local name = node.name
		local interfaces = node.interfaces
		local directives = node.directives
		local fields = node.fields
		return join(
			{
				"extend type",
				name,
				wrap("implements ", join(interfaces, " & ")),
				join(directives, " "),
				block(fields),
			},
			" "
		)
	end,

	InterfaceTypeExtension = function(_self, node)
		local name = node.name
		local interfaces = node.interfaces
		local directives = node.directives
		local fields = node.fields
		return join(
			{
				"extend interface",
				name,
				wrap("implements ", join(interfaces, " & ")),
				join(directives, " "),
				block(fields),
			},
			" "
		)
	end,

	UnionTypeExtension = function(_self, node)
		local name = node.name
		local directives = node.directives
		local types = node.types
		return join(
			{
				"extend union",
				name,
				join(directives, " "),
				(function()
					if types and #types ~= 0 then
						return "= " .. join(types, " | ")
					else
						return ""
					end
				end)(),
			},
			" "
		)
	end,

	EnumTypeExtension = function(_self, node)
		local name = node.name
		local directives = node.directives
		local values = node.values
		return join({ "extend enum", name, join(directives, " "), block(values) }, " ")
	end,

	InputObjectTypeExtension = function(_self, node)
		local name = node.name
		local directives = node.directives
		local fields = node.fields
		return join({ "extend input", name, join(directives, " "), block(fields) }, " ")
	end,
}

--[[**
--  * Given maybeArray, print an empty string if it is null or empty, otherwise
--  * print all items together separated by separator if provided
--  *]]
function join(maybeArray: Array<string>?, separator: string?): string
	separator = separator or ""
	if maybeArray then
		return UtilArray.join(
			Array.filter(maybeArray, function(x)
				return x and x ~= ""
			end),
			separator
		)
	else
		return ""
	end
end

-- /**
--  * Given array, print each item on its own line, wrapped in an
--  * indented "{ }" block.
--  */
function block(array: Array<string>?): string
	return wrap("{\n", indent(join(array, "\n")), "\n}")
end

--[[**
--  * If maybeString is not nil or empty, then wrap with start and end, otherwise print an empty string.
--  *]]
function wrap(start: string, maybeString: string?, end_: string?): string
	end_ = end_ or ""
	if maybeString ~= nil and maybeString ~= "" then
		-- ROBLOX FIXME: Luau nil refinement improvements needed to remove tostring(maybeString)
		return start .. tostring(maybeString) .. tostring(end_)
	else
		return ""
	end
end

function indent(str: string): string
	-- ROBLOX deviation: separate local variable is necessary
	-- string.gsub return total nr of matches as a 2nd returned value
	local substr = str:gsub("\n", "\n  ")
	return wrap("  ", substr)
end

function isMultiline(str: string): boolean
	return str:find("\n") ~= nil
end

function hasMultilineItems(maybeArray: Array<string>?): boolean
	return maybeArray ~= nil and Array.some(maybeArray, isMultiline)
end

return {
	print = print_,
}
