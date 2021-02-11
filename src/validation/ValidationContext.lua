-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/661ff1a6b591eea1e7a7e7c9e6b8b2dcfabf3bd7/src/validation/ValidationContext.js

local root = script.Parent.Parent
local language = root.language
local Kind = require(language.kinds).Kind
local visitor = require(language.visitor)
local visit = visitor.visit
type ASTVisitor = any -- visitor.ASTVisitor

local _ast = require(language.ast)
type DocumentNode = _ast.DocumentNode
type OperationDefinitionNode = _ast.OperationDefinitionNode
type VariableNode = _ast.VariableNode
type SelectionSetNode = _ast.SelectionSetNode
type FragmentSpreadNode = _ast.FragmentSpreadNode
type FragmentDefinitionNode = _ast.FragmentDefinitionNode

local _GraphQLErrorExports = require(root.error.GraphQLError)
type GraphQLError = _GraphQLErrorExports.GraphQLError

local TypeInfoExports = require(root.utilities.TypeInfo)
local TypeInfo = TypeInfoExports.TypeInfo
local visitWithTypeInfo = TypeInfoExports.visitWithTypeInfo
type TypeInfo = TypeInfoExports.TypeInfo

local _schemaExports = require(root.type.schema)
type GraphQLSchema = _schemaExports.GraphQLSchema
-- local _directivesExports = require(root.type.directives)
type GraphQLDirective = any -- _directivesExports.GraphQLDirective

-- local _definition = require(root.type.definition)
type GraphQLInputType = any -- _definition.GraphQLInputType
type GraphQLOutputType = any -- _definition.GraphQLOutputType
type GraphQLCompositeType = any -- _definition.GraphQLCompositeType
type GraphQLField<T, U> = any -- _definition.GraphQLField<T, U>
type GraphQLArgument = any -- _definition.GraphQLArgument
type GraphQLEnumValue = any -- _definition.GraphQLEnumValue

local Array = require(root.luaUtils.Array)

type NodeWithSelectionSet = OperationDefinitionNode | FragmentDefinitionNode
type VariableUsage = {
	node: VariableNode,
	type: GraphQLInputType?,
	defaultValue: any?,
}
type Array<T> = { [number]: T }

-- /**
--  * An instance of this class is passed as the "this" context to all validators,
--  * allowing access to commonly useful contextual information from within a
--  * validation rule.
--  */
local ASTValidationContext = {}
local ASTValidationContextMetatable = {__index = ASTValidationContext}

function ASTValidationContext.new(ast: DocumentNode, onError: (GraphQLError) -> ())
	return setmetatable({
		_ast = ast,
		_fragments = nil,
		_fragmentSpreads = {},
		_recursivelyReferencedFragments = {},
		_onError = onError,
	}, ASTValidationContextMetatable)
end

function ASTValidationContext:reportError(error_: GraphQLError)
	self._onError(error_)
end

function ASTValidationContext:getDocument(): DocumentNode
	return self._ast
end

function ASTValidationContext:getFragment(name: string): FragmentDefinitionNode?
	local fragments = self._fragments
	if not fragments then
		fragments = Array.reduce(self:getDocument().definitions, function(frags, statement)
			if statement.kind == Kind.FRAGMENT_DEFINITION then
				frags[statement.name.value] = statement
			end
			return frags
		end, {})
		self._fragments = fragments
	end
	return fragments[name]
end

function ASTValidationContext:getFragmentSpreads(
	node: SelectionSetNode
): Array<FragmentSpreadNode>
	local spreads = self._fragmentSpreads[node]
	if not spreads then
		spreads = {}
		local setsToVisit: Array<SelectionSetNode> = {node}
		while #setsToVisit ~= 0 do
			local set = table.remove(setsToVisit)
			for _, selection in ipairs(set.selections)do
				if selection.kind == Kind.FRAGMENT_SPREAD then
					table.insert(spreads, selection)
				elseif selection.selectionSet then
					table.insert(setsToVisit, selection.selectionSet)
				end
			end
		end
		self._fragmentSpreads[node] = spreads
	end
	return spreads
end

function ASTValidationContext:getRecursivelyReferencedFragments(
	operation: OperationDefinitionNode
): Array<FragmentDefinitionNode>
	local fragments = self._recursivelyReferencedFragments[operation]
	if not fragments then
		fragments = {}
		local collectedNames = {}
		local nodesToVisit = {operation.selectionSet}
		while #nodesToVisit ~= 0 do
			local node = table.remove(nodesToVisit)
			for _, spread in ipairs(self:getFragmentSpreads(node))do
				local fragName = spread.name.value
				if collectedNames[fragName] ~= true then
					collectedNames[fragName] = true
					local fragment = self:getFragment(fragName)
					if fragment then
						table.insert(fragments, fragment)
						table.insert(nodesToVisit, fragment.selectionSet)
					end
				end
			end
		end
		self._recursivelyReferencedFragments[operation] = fragments
	end
	return fragments
end

-- export type ASTValidationRule = (ASTValidationContext) -> ASTVisitor

local SDLValidationContext = setmetatable({}, {__index = ASTValidationContext})
local SDLValidationContextMetatable = {__index = SDLValidationContext}

function SDLValidationContext.new(
	ast: DocumentNode,
	schema: GraphQLSchema?,
	onError: (GraphQLError) -> ()
)
	local self = setmetatable(
		ASTValidationContext.new(ast, onError),
		SDLValidationContextMetatable
	)
	self._schema = schema
	return self
end

function SDLValidationContext:getSchema(): GraphQLSchema?
	return self._schema
end

-- export type SDLValidationRule = (SDLValidationContext) -> ASTVisitor

local ValidationContext = setmetatable({}, {__index = ASTValidationContext})
local ValidationContextMetatable = {__index = ValidationContext}

function ValidationContext.new(
	schema: GraphQLSchema,
	ast: DocumentNode,
	typeInfo: TypeInfo,
	onError: (GraphQLError) -> ()
)
	local self = setmetatable(
		ASTValidationContext.new(ast, onError),
		ValidationContextMetatable
	)
	self._schema = schema
	self._typeInfo = typeInfo
	self._variableUsages = {}
	self._recursiveVariableUsages = {}
	return self
end

function ValidationContext:getSchema(): GraphQLSchema
	return self._schema
end

function ValidationContext:getVariableUsages(
	node: NodeWithSelectionSet
): Array<VariableUsage>
	local usages = self._variableUsages[node]
	if not usages then
		local newUsages = {}
		local typeInfo = TypeInfo.new(self._schema)
		visit(
			node,
			visitWithTypeInfo(typeInfo, {
				VariableDefinition = function()
					return false
				end,
				Variable = function(_self, variable)
					table.insert(newUsages, {
						node = variable,
						type = typeInfo:getInputType(),
						defaultValue = typeInfo:getDefaultValue(),
					})
				end,
			})
		)
		usages = newUsages
		self._variableUsages[node] = usages
	end

	return usages
end

function ValidationContext:getRecursiveVariableUsages(
	operation: OperationDefinitionNode
): Array<VariableUsage>
	local usages = self._recursiveVariableUsages[operation]
	if not usages then
		usages = self:getVariableUsages(operation)
		for _, frag in ipairs(self:getRecursivelyReferencedFragments(operation))do
			usages = Array.concat(usages, self:getVariableUsages(frag))
		end
		self._recursiveVariableUsages[operation] = usages
	end
	return usages
end

function ValidationContext:getType(): GraphQLOutputType?
	return self._typeInfo:getType()
end

function ValidationContext:getParentType(): GraphQLCompositeType?
	return self._typeInfo:getParentType()
end

function ValidationContext:getInputType(): GraphQLInputType?
	return self._typeInfo:getInputType()
end

function ValidationContext:getParentInputType(): GraphQLInputType?
	return self._typeInfo:getParentInputType()
end

function ValidationContext:getFieldDef(): GraphQLField<any, any>?
	return self._typeInfo:getFieldDef()
end

function ValidationContext:getDirective(): GraphQLDirective?
	return self._typeInfo:getDirective()
end

function ValidationContext:getArgument(): GraphQLArgument?
	return self._typeInfo:getArgument()
end

function ValidationContext:getEnumValue(): GraphQLEnumValue?
	return self._typeInfo:getEnumValue()
end

-- export type ValidationRule = (ValidationContext) -> ASTVisitor

return {
	ASTValidationContext = ASTValidationContext,
	SDLValidationContext = SDLValidationContext,
	ValidationContext = ValidationContext,
}
