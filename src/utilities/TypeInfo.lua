-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/TypeInfo.js
--!strict
local srcWorkspace = script.Parent.Parent
local Packages = srcWorkspace.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>

local language = srcWorkspace.language
local typeWorkspace = srcWorkspace.type

local visitorImport = require(language.visitor)
local astImport = require(language.ast)
-- ROBLOX deviation: Luau can't do default type args, so we inline here
type Visitor<T> = visitorImport.Visitor<T, any>
-- ROBLOX TODO: looks like a type violation in upstream, not all members of ASTNode union have 'name' or 'value' fields
type TypeNode = astImport.TypeNode
type NameNode = astImport.NameNode
type NamedTypeNode = astImport.NamedTypeNode
type ASTNode = {
	kind: string,
	name: NameNode,
	value: string,
	operation: any,
	typeCondition: NamedTypeNode,
	type: TypeNode,
} -- astImport.ASTNode
type ASTKindToNode = astImport.ASTKindToNode
type FieldNode = astImport.FieldNode
local Kind = require(language.kinds).Kind
local isNode = astImport.isNode
local getVisitFn = visitorImport.getVisitFn

local schemaImport = require(typeWorkspace.schema)
type GraphQLSchema = schemaImport.GraphQLSchema
local _directivesImport = require(typeWorkspace.directives)
type GraphQLDirective = _directivesImport.GraphQLDirective
local definitionImport = require(typeWorkspace.definition)
type GraphQLType = definitionImport.GraphQLType
type GraphQLInputType = definitionImport.GraphQLInputType
type GraphQLOutputType = definitionImport.GraphQLOutputType
type GraphQLCompositeType = definitionImport.GraphQLCompositeType
-- ROBLOX deviation: Luau can't do default type args, so we inline here
type GraphQLField<T, U> = definitionImport.GraphQLField<T, U, any>
type GraphQLArgument = definitionImport.GraphQLArgument
type GraphQLInputField = definitionImport.GraphQLInputField
type GraphQLEnumValue = definitionImport.GraphQLEnumValue
local isObjectType = definitionImport.isObjectType
local isInterfaceType = definitionImport.isInterfaceType
local isEnumType = definitionImport.isEnumType
local isInputObjectType = definitionImport.isInputObjectType
local isListType = definitionImport.isListType
local isCompositeType = definitionImport.isCompositeType
local isInputType = definitionImport.isInputType
local isOutputType = definitionImport.isOutputType
local getNullableType = definitionImport.getNullableType
local getNamedType = definitionImport.getNamedType
local introspectionImport = require(typeWorkspace.introspection)
local SchemaMetaFieldDef = introspectionImport.SchemaMetaFieldDef
local TypeMetaFieldDef = introspectionImport.TypeMetaFieldDef
local TypeNameMetaFieldDef = introspectionImport.TypeNameMetaFieldDef

local typeFromAST = require(srcWorkspace.utilities.typeFromAST).typeFromAST

-- ROBLOX deviation: use the following table as a symbol to represent
-- a `null` value within the arrays
local NULL = {}
local function unwrapNull(value)
	if value == NULL then
		return nil
	end
	return value
end

-- /**
--  * TypeInfo is a utility class which, given a GraphQL schema, can keep track
--  * of the current field and type definitions at any point in a GraphQL document
--  * AST during a recursive descent by calling `enter(node)` and `leave(node)`.
--  */
local TypeInfo = {}
local TypeInfoMetatable = { __index = TypeInfo }

export type TypeInfo = {
	_schema: GraphQLSchema,
	_typeStack: Array<GraphQLOutputType?>,
	_parentTypeStack: Array<GraphQLCompositeType?>,
	_inputTypeStack: Array<GraphQLInputType?>,
	_fieldDefStack: Array<GraphQLField<any, any>?>,
	_defaultValueStack: Array<any?>,
	_directive: GraphQLDirective?,
	_argument: GraphQLArgument?,
	_enumValue: GraphQLEnumValue?,
	_getFieldDef: (GraphQLSchema, GraphQLType, FieldNode) -> GraphQLField<any, any>?,
	-- functions
	getType: (self: TypeInfo) -> GraphQLOutputType?,
	getParentType: (self: TypeInfo) -> GraphQLCompositeType?,
	getInputType: (self: TypeInfo) -> GraphQLInputType?,
	getParentInputType: (self: TypeInfo) -> GraphQLInputType?,
	getFieldDef: (self: TypeInfo) -> GraphQLField<any, any>?,
	getDefaultValue: (self: TypeInfo) -> any?,
	getDirective: (self: TypeInfo) -> GraphQLDirective?,
	getArgument: (self: TypeInfo) -> GraphQLArgument?,
	getEnumValue: (self: TypeInfo) -> GraphQLEnumValue?,
	enter: (self: TypeInfo, ASTNode) -> (),
	leave: (self: TypeInfo, ASTNode) -> (),
}

-- ROBLOX deviation: pre-declare variables
local getFieldDef

function TypeInfo.new(
	schema: GraphQLSchema,
	-- @deprecated will be removed in 17.0.0
	getFieldDefFn: ((GraphQLSchema, GraphQLType, FieldNode) -> GraphQLField<any, any>?)?,
	-- // Initial type may be provided in rare cases to facilitate traversals
	-- // beginning somewhere other than documents.
	--[[* @deprecated will be removed in 17.0.0 ]]
	initialType: GraphQLType?
): TypeInfo
	local self = (setmetatable({}, TypeInfoMetatable) :: any) :: TypeInfo
	self._schema = schema
	self._typeStack = {}
	self._parentTypeStack = {}
	self._inputTypeStack = {}
	self._fieldDefStack = {}
	self._defaultValueStack = {}
	self._directive = nil
	self._argument = nil
	self._enumValue = nil
	self._getFieldDef = getFieldDefFn or getFieldDef

	if initialType then
		if isInputType(initialType) then
			table.insert(self._inputTypeStack, initialType)
		end
		if isCompositeType(initialType) then
			table.insert(self._parentTypeStack, initialType)
		end
		if isOutputType(initialType) then
			table.insert(self._typeStack, initialType)
		end
	end

	return self
end

function TypeInfo:getType(): GraphQLOutputType?
	if #self._typeStack > 0 then
		return unwrapNull(self._typeStack[#self._typeStack])
	end
	return nil
end

function TypeInfo:getParentType(): GraphQLCompositeType?
	if #self._parentTypeStack > 0 then
		return unwrapNull(self._parentTypeStack[#self._parentTypeStack])
	end
	return nil
end

function TypeInfo:getInputType(): GraphQLInputType?
	if #self._inputTypeStack > 0 then
		return unwrapNull(self._inputTypeStack[#self._inputTypeStack])
	end
	return nil
end

function TypeInfo:getParentInputType(): GraphQLInputType?
	if #self._inputTypeStack > 1 then
		return unwrapNull(self._inputTypeStack[#self._inputTypeStack - 1])
	end
	return nil
end

function TypeInfo:getFieldDef(): GraphQLField<any, any>?
	if #self._fieldDefStack > 0 then
		return unwrapNull(self._fieldDefStack[#self._fieldDefStack])
	end
	return nil
end

function TypeInfo:getDefaultValue(): any?
	if #self._defaultValueStack > 0 then
		return unwrapNull(self._defaultValueStack[#self._defaultValueStack])
	end
	return nil
end

function TypeInfo:getDirective(): GraphQLDirective?
	return self._directive
end

function TypeInfo:getArgument(): GraphQLArgument?
	return self._argument
end

function TypeInfo:getEnumValue(): GraphQLEnumValue?
	return self._enumValue
end

function TypeInfo:enter(node: ASTNode)
	local schema = self._schema
	-- // Note: many of the types below are explicitly typed as "mixed" to drop
	-- // any assumptions of a valid schema to ensure runtime types are properly
	-- // checked before continuing since TypeInfo is used as part of validation
	-- // which occurs before guarantees of schema and document validity.
	local nodeKind = node.kind
	if nodeKind == Kind.SELECTION_SET then
		local namedType = getNamedType(self:getType())
		table.insert(
			self._parentTypeStack,
			(function()
				if isCompositeType(namedType) then
					return namedType
				end
				return NULL
			end)()
		)
		return
	elseif nodeKind == Kind.FIELD then
		local parentType = self:getParentType()
		local fieldDef
		local fieldType
		if parentType then
			fieldDef = self._getFieldDef(schema, parentType, node)
			if fieldDef then
				fieldType = fieldDef.type
			end
		end
		table.insert(self._fieldDefStack, if fieldDef then fieldDef else NULL)
		table.insert(self._typeStack, if isOutputType(fieldType) then fieldType else NULL)
		return
	elseif nodeKind == Kind.DIRECTIVE then
		self._directive = schema:getDirective(node.name.value)
		return
	elseif nodeKind == Kind.OPERATION_DEFINITION then
		local type_
		local nodeOperation = node.operation
		if nodeOperation == "query" then
			type_ = schema:getQueryType()
		elseif nodeOperation == "mutation" then
			type_ = schema:getMutationType()
		elseif nodeOperation == "subscription" then
			type_ = schema:getSubscriptionType()
		end
		table.insert(self._typeStack, if isObjectType(type_) then type_ else NULL)
		return
	elseif nodeKind == Kind.INLINE_FRAGMENT or nodeKind == Kind.FRAGMENT_DEFINITION then
		local typeConditionAST = node.typeCondition
		local outputType = (function()
			if typeConditionAST then
				return typeFromAST(schema, typeConditionAST)
			end
			return getNamedType(self:getType())
		end)()
		table.insert(self._typeStack, if isOutputType(outputType) then outputType else NULL)
		return
	elseif nodeKind == Kind.VARIABLE_DEFINITION then
		local inputType = typeFromAST(schema, node.type)
		table.insert(self._inputTypeStack, if isInputType(inputType) then inputType else NULL)
		return
	elseif nodeKind == Kind.ARGUMENT then
		local argDef
		local argType
		local fieldOrDirective = (function()
			local _ref = self:getDirective()
			if _ref == nil then
				_ref = self:getFieldDef()
			end
			return _ref
		end)()
		if fieldOrDirective then
			argDef = Array.find(fieldOrDirective.args, function(arg)
				return arg.name == node.name.value
			end)
			if argDef then
				argType = argDef.type
			end
		end
		self._argument = argDef
		table.insert(self._defaultValueStack, if argDef then argDef.defaultValue else NULL)
		table.insert(self._inputTypeStack, if isInputType(argType) then argType else NULL)
		return
	elseif nodeKind == Kind.LIST then
		local listType = getNullableType(self:getInputType())
		local itemType = if isListType(listType) then listType.ofType else listType
		-- // List positions never have a default value.
		table.insert(self._defaultValueStack, NULL)
		table.insert(self._inputTypeStack, if isInputType(itemType) then itemType else NULL)
		return
	elseif nodeKind == Kind.OBJECT_FIELD then
		local objectType = getNamedType(self:getInputType())
		local inputFieldType
		local inputField
		if isInputObjectType(objectType) then
			-- ROBLOX deviation: use Map
			inputField = objectType:getFields():get(node.name.value)
			if inputField then
				inputFieldType = inputField.type
			end
		end
		table.insert(self._defaultValueStack, if inputField then inputField.defaultValue else NULL)
		table.insert(self._inputTypeStack, if isInputType(inputFieldType) then inputFieldType else NULL)
		return
	elseif nodeKind == Kind.ENUM then
		local enumType = getNamedType(self:getInputType())
		local enumValue
		if isEnumType(enumType) then
			enumValue = enumType:getValue(node.value)
		end
		self._enumValue = enumValue
		return
	end
end

function TypeInfo:leave(node: ASTNode)
	local nodeKind = node.kind
	if nodeKind == Kind.SELECTION_SET then
		table.remove(self._parentTypeStack)
	elseif nodeKind == Kind.FIELD then
		table.remove(self._fieldDefStack)
		table.remove(self._typeStack)
	elseif nodeKind == Kind.DIRECTIVE then
		self._directive = nil
	elseif
		nodeKind == Kind.OPERATION_DEFINITION
		or nodeKind == Kind.INLINE_FRAGMENT
		or nodeKind == Kind.FRAGMENT_DEFINITION
	then
		table.remove(self._typeStack)
	elseif nodeKind == Kind.VARIABLE_DEFINITION then
		table.remove(self._inputTypeStack)
	elseif nodeKind == Kind.ARGUMENT then
		self._argument = nil
		table.remove(self._defaultValueStack)
		table.remove(self._inputTypeStack)
	elseif nodeKind == Kind.LIST or nodeKind == Kind.OBJECT_FIELD then
		table.remove(self._defaultValueStack)
		table.remove(self._inputTypeStack)
	elseif nodeKind == Kind.ENUM then
		self._enumValue = nil
	end
end

-- /**
--  * Not exactly the same as the executor's definition of getFieldDef, in this
--  * statically evaluated environment we do not always have an Object type,
--  * and need to handle Interface and Union types.
--  */
function getFieldDef(schema: GraphQLSchema, parentType: GraphQLType, fieldNode: FieldNode): GraphQLField<any, any>?
	local name = fieldNode.name.value

	if name == SchemaMetaFieldDef.name and schema:getQueryType() == parentType then
		return SchemaMetaFieldDef
	end
	if name == TypeMetaFieldDef.name and schema:getQueryType() == parentType then
		return TypeMetaFieldDef
	end
	if name == TypeNameMetaFieldDef.name and isCompositeType(parentType) then
		return TypeNameMetaFieldDef
	end
	if isObjectType(parentType) or isInterfaceType(parentType) then
		-- ROBLOX deviation: use Map
		return parentType:getFields():get(name)
	end
	return nil
end

-- /**
--  * Creates a new visitor instance which maintains a provided TypeInfo instance
--  * along with visiting visitor.
--  */
local function visitWithTypeInfo(typeInfo: TypeInfo, visitor: Visitor<ASTKindToNode>): Visitor<ASTKindToNode>
	return {
		enter = function(_self, node, ...)
			typeInfo:enter(node)
			local fn = getVisitFn(
				visitor,
				node.kind, --[[ isLeaving ]]
				false
			)
			if fn then
				local result = fn(visitor, node, ...)
				if result ~= nil then
					typeInfo:leave(node)
					if isNode(result) then
						typeInfo:enter(result)
					end
				end
				return result
			end
			return nil
		end,
		leave = function(_self, node, ...)
			local fn = getVisitFn(
				visitor,
				node.kind, --[[ isLeaving ]]
				true
			)
			local result
			if fn then
				result = fn(visitor, node, ...)
			end
			typeInfo:leave(node)
			return result
		end,
	}
end

return {
	TypeInfo = TypeInfo,
	visitWithTypeInfo = visitWithTypeInfo,
}
