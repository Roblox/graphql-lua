-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/661ff1a6b591eea1e7a7e7c9e6b8b2dcfabf3bd7/src/validation/ValidationContext.js
-- ROBLOX deviation: use map type
local srcWorkspace = script.Parent.Parent
type Map<T,V> = { [T]: V }
local jsutilsWorkspace = srcWorkspace.jsutils
local ObjMap = require(jsutilsWorkspace.ObjMap)
type ObjMap<T> = ObjMap.ObjMap<T>

local language = srcWorkspace.language
local Kind = require(language.kinds).Kind
local visitor = require(language.visitor)
local visit = visitor.visit
type ASTVisitor = visitor.ASTVisitor

local _ast = require(language.ast)
type DocumentNode = _ast.DocumentNode
type OperationDefinitionNode = _ast.OperationDefinitionNode
type VariableNode = _ast.VariableNode
type SelectionSetNode = _ast.SelectionSetNode
type FragmentSpreadNode = _ast.FragmentSpreadNode
type FragmentDefinitionNode = _ast.FragmentDefinitionNode

local _GraphQLErrorExports = require(srcWorkspace.error.GraphQLError)
type GraphQLError = _GraphQLErrorExports.GraphQLError

local TypeInfoExports = require(srcWorkspace.utilities.TypeInfo)
local TypeInfo = TypeInfoExports.TypeInfo
local visitWithTypeInfo = TypeInfoExports.visitWithTypeInfo
type TypeInfo = TypeInfoExports.TypeInfo

local _schemaExports = require(srcWorkspace.type.schema)
type GraphQLSchema = _schemaExports.GraphQLSchema
local directivesExports = require(srcWorkspace.type.directives)
type GraphQLDirective = directivesExports.GraphQLDirective

local definitionModule = require(srcWorkspace.type.definition)
type GraphQLInputType = definitionModule.GraphQLInputType
type GraphQLOutputType = definitionModule.GraphQLOutputType
type GraphQLCompositeType = definitionModule.GraphQLCompositeType
-- ROBLOX TODO: Luau doesn't currently support default type arguments, so we inline here
type GraphQLFieldDefaultTArgs = { [string]: any }
type GraphQLField<T, U> = definitionModule.GraphQLField<T, U, GraphQLFieldDefaultTArgs>
type GraphQLArgument = definitionModule.GraphQLArgument
type GraphQLEnumValue = definitionModule.GraphQLEnumValue

local Array = require(srcWorkspace.luaUtils.Array)

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
-- ROBLOX TODO: add proper type
export type ASTValidationContext = {
	_ast: DocumentNode,
	_onError: (GraphQLError) -> (),
	_fragments: ObjMap<FragmentDefinitionNode>?,
	_fragmentSpreads: Map<SelectionSetNode, Array<FragmentSpreadNode>>,
	_recursivelyReferencedFragments: Map<
	  OperationDefinitionNode,
	  Array<FragmentDefinitionNode>
	>,
	reportError: (GraphQLError) -> (),
	getDocument: () -> DocumentNode,
	getFragment: (string) -> FragmentDefinitionNode?,
	getFragmentSpreads: (SelectionSetNode) -> Array<FragmentSpreadNode>,
	getRecursivelyReferencedFragments: (OperationDefinitionNode) -> Array<FragmentDefinitionNode>
}

local ASTValidationContext = {}
local ASTValidationContextMetatable = {__index = ASTValidationContext}

function ASTValidationContext.new(
	ast: DocumentNode,
	onError: (GraphQLError) -> ()
) -- ROBLOX TODO: Luau doesn't think this metatable is convertible to: ASTValidationContext
	return setmetatable({
		_ast = ast,
		_fragments = nil,
		_fragmentSpreads = {},
		_recursivelyReferencedFragments = {},
		_onError = onError,
	}, ASTValidationContextMetatable)
end

function ASTValidationContext:reportError(error_: GraphQLError): ()
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

export type ASTValidationRule = (ASTValidationContext) -> ASTVisitor

export type SDLValidationContext = ASTValidationContext & {
	_schema: GraphQLSchema?,

	-- ROBLOX deviation: add argument for self
	getSchema: () -> GraphQLSchema?
}
local SDLValidationContext = setmetatable({}, {__index = ASTValidationContext})
local SDLValidationContextMetatable = {__index = SDLValidationContext}

function SDLValidationContext.new(
	ast: DocumentNode,
	schema: GraphQLSchema?,
	onError: (GraphQLError) -> ()
): SDLValidationContext
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

export type SDLValidationRule = (SDLValidationContext) -> ASTVisitor

export type ValidationContext = ASTValidationContext & {
	_schema: GraphQLSchema,
	_typeInfo: TypeInfo,
	_variableUsages: Map<NodeWithSelectionSet, Array<VariableUsage>>,
	_recursiveVariableUsages: Map<
	  OperationDefinitionNode,
	  Array<VariableUsage>
	>,
	-- ROBLOX deviation: add argument for self
	getSchema: (any) -> GraphQLSchema,
	getVariableUsages: (any, NodeWithSelectionSet) -> Array<VariableUsage>,
	getRecursiveVariableUsages: (any, OperationDefinitionNode) -> Array<VariableUsage>,
	getType: (any) -> GraphQLOutputType?,
	getParentType: (any) -> GraphQLCompositeType?,
	getInputType: (any) -> GraphQLInputType?,
	getParentInputType: (any) -> GraphQLInputType?,
	getFieldDef: (any) -> GraphQLField<any, any>?,
	getDirective: (any) -> GraphQLDirective?,
	getArgument: (any) -> GraphQLArgument?,
	getEnumValue: (any) -> GraphQLEnumValue?
}

local ValidationContext = setmetatable({}, {__index = ASTValidationContext})
local ValidationContextMetatable = {__index = ValidationContext}

function ValidationContext.new(
	schema: GraphQLSchema,
	ast: DocumentNode,
	typeInfo: TypeInfo,
	onError: (GraphQLError) -> ()
): ValidationContext
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

export type ValidationRule = (ValidationContext) -> ASTVisitor

return {
	ASTValidationContext = ASTValidationContext,
	SDLValidationContext = SDLValidationContext,
	ValidationContext = ValidationContext,
}
