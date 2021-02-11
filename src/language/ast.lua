-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/ast.js
local languageWorkspace = script.Parent
local _source = require(languageWorkspace.source)
type Source = _source.Source
local _tokenKind = require(languageWorkspace.tokenKind)
type TokenKindEnum = _tokenKind.TokenKindEnum

type Array<T> = { [number]: T }

export type Location = {
	-- /**
	--  * The character offset at which this Node begins.
	--  */
	start: number,

	-- /**
	--  * The character offset at which this Node ends.
	--  */
	_end: number,

	-- /**
	--  * The Token at which this Node begins.
	--  */
	startToken: Token,

	-- /**
	--  * The Token at which this Node ends.
	--  */
	endToken: Token,

	-- /**
	--  * The Source document the AST represents.
	--  */
	source: Source,
}

local Location = {}
Location.__index = Location

function Location.new(startToken: Token, endToken: Token, source: Source)
	local self = {}
	self.start = startToken.start
	-- ROBLOX FIXME: rename `_end` to `end_`
	self._end = endToken._end
	self.startToken = startToken
	self.endToken = endToken
	self.source = source

	return setmetatable(self, Location)
end

function Location:toJSON()
	return { start = self.start, _end = self._end }
end

-- ROBLOX deviation: don't implement since it's already slated for removal
-- @deprecated: Will be removed in v17
-- [Symbol.for('nodejs.util.inspect.custom')](): mixed {
--     return this.toJSON();
--   }

export type Token = {
	-- /**
	-- * The kind of Token.
	-- */
	kind: TokenKindEnum,

	-- /**
	-- * The character offset at which this Node begins.
	-- */
	start: number,

	-- /**
	-- * The character offset at which this Node ends.
	-- */
	_end: number,

	-- /**
	-- * The 1-indexed line number on which this Token appears.
	-- */
	line: number,

	-- /**
	-- * The 1-indexed column number at which this Token begins.
	-- */
	column: number,

	-- /**
	-- * For non-punctuation tokens, represents the interpreted value of the token.
	-- */
	value: string | nil,

	-- /**
	-- * Tokens exist as nodes in a double-linked-list amongst all tokens
	-- * including ignored tokens. <SOF> is always the first node and <EOF>
	-- * the last.
	-- */
	prev: Token | nil,
	next: Token | nil,
}

--[[*
 * Represents a range of characters represented by a lexical token
 * within a Source.
 ]]
local Token = {}
Token.__index = Token

function Token.new(
	kind,
	start: number,
	-- ROBLOX FIXME: rename `_end` to `end_`
	_end: number,
	line: number,
	column: number,
	prev,
	value: string
)
	local self = {}
	self.kind = kind
	self.start = start
	self._end = _end
	self.line = line
	self.column = column
	self.value = value
	self.prev = prev
	self.next = nil

	return setmetatable(self, Token)
end

function Token:toJSON()
	return {
		kind = self.kind,
		value = self.value,
		line = self.line,
		column = self.column,
	}
end

-- ROBLOX deviation: don't implement since it's already slated for removal
-- @deprecated: Will be removed in v17
-- [Symbol.for('nodejs.util.inspect.custom')](): mixed {
--     return this.toJSON();
--   }

local function isNode(maybeNode: any): boolean
	-- ROBLOX deviation: we need to check for a table in Lua, because we
	-- need to check if `maybeNode.kind` is a string. In JS, this function
	-- can be given a boolean which can be indexed safely, but in Lua it will
	-- throw.
	return typeof(maybeNode) == "table" and typeof(maybeNode.kind) == "string"
end

-- // Name

export type NameNode = {
	-- kind: 'Name',
	kind: string,
	loc: Location?,
	value: string,
}

-- // Document
-- ...

export type DocumentNode = {
	-- kind: 'Document',
	kind: string,
	loc: Location?,
	definitions: Array<DefinitionNode>,
}

export type DefinitionNode =
	ExecutableDefinitionNode
	| TypeSystemDefinitionNode
	| TypeSystemExtensionNode

export type ExecutableDefinitionNode =
	OperationDefinitionNode
	| FragmentDefinitionNode

export type OperationDefinitionNode = {
	-- kind: 'OperationDefinition',
	kind: string,
	loc: Location?,
	operation: OperationTypeNode,
	name: NameNode?,
	variableDefinitions: Array<VariableDefinitionNode>?,
	directives: Array<DirectiveNode>?,
	selectionSet: SelectionSetNode,
}

export type OperationTypeNode = string -- 'query' | 'mutation' | 'subscription'

export type VariableDefinitionNode = {
	-- kind: 'VariableDefinition',
	kind: string,
	loc: Location?,
	variable: VariableNode,
	type: TypeNode,
	defaultValue: ValueNode?,
	directives: Array<DirectiveNode>?,
}

export type VariableNode = {
	-- kind: 'Variable',
	kind: string,
	loc: Location?,
	name: NameNode,
}

export type SelectionSetNode = {
	-- kind: 'SelectionSet',
	kind: string,
	loc: Location?,
	selections: Array<SelectionNode>,
}

export type SelectionNode = FieldNode | FragmentSpreadNode | InlineFragmentNode

export type FieldNode = {
	-- kind: 'Field',
	kind: string,
	loc: Location?,
	alias: NameNode?,
	name: NameNode,
	arguments: Array<ArgumentNode>?,
	directives: Array<DirectiveNode>?,
	selectionSet: SelectionSetNode?,
}

export type ArgumentNode = {
	-- kind: 'Argument',
	kind: string,
	loc: Location?,
	name: NameNode,
	value: ValueNode,
}

-- // Fragments

export type FragmentSpreadNode = {
	-- kind: 'FragmentSpread',
	kind: string,
	loc: Location?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
}

export type InlineFragmentNode = {
	-- kind: 'InlineFragment',
	kind: string,
	loc: Location?,
	typeCondition: NamedTypeNode?,
	directives: Array<DirectiveNode>?,
	selectionSet: SelectionSetNode,
}

export type FragmentDefinitionNode = {
	-- kind: 'FragmentDefinition',
	kind: string,
	loc: Location?,
	name: NameNode,
	-- // Note: fragment variable definitions are experimental and may be changed
	-- // or removed in the future.
	variableDefinitions: Array<VariableDefinitionNode>?,
	typeCondition: NamedTypeNode,
	directives: Array<DirectiveNode>?,
	selectionSet: SelectionSetNode,
}

-- // Values

export type ValueNode =
	VariableNode
	| IntValueNode
	| FloatValueNode
	| StringValueNode
	-- | BooleanValueNode
	-- | NullValueNode
	-- | EnumValueNode
	-- | ListValueNode
	-- | ObjectValueNode

export type IntValueNode = {
	-- kind: 'IntValue',
	kind: string,
	loc: Location?,
	value: string,
};

export type FloatValueNode = {
	-- kind: 'FloatValue',
	kind: string,
	loc: Location?,
	value: string,
};

export type StringValueNode = {
	-- kind: 'StringValue',
	kind: string,
	loc: Location?,
	value: string,
	block: boolean?,
}

-- ...

-- // Directives

export type DirectiveNode = {
	-- kind: 'Directive',
	kind: string,
	loc: Location?,
	name: NameNode,
	arguments: Array<ArgumentNode>?,
}

-- // Type Reference

export type TypeNode = NamedTypeNode | ListTypeNode | NonNullTypeNode

export type NamedTypeNode = {
	-- kind: 'NamedType',
	kind: string,
	loc: Location?,
	name: NameNode,
}

export type ListTypeNode = {
	-- kind: 'ListType',
	kind: string,
	loc: Location?,
	type: TypeNode,
}

export type NonNullTypeNode = {
	-- kind: 'NonNullType',
	kind: string,
	loc: Location?,
	type: NamedTypeNode | ListTypeNode,
}

-- // Type System Definition

export type TypeSystemDefinitionNode =
	SchemaDefinitionNode
	-- | TypeDefinitionNode
	-- | DirectiveDefinitionNode

export type SchemaDefinitionNode = {
	-- kind: 'SchemaDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	directives: Array<DirectiveNode>?,
	operationTypes: Array<OperationTypeDefinitionNode>,
}

export type OperationTypeDefinitionNode = {
	-- kind: 'OperationTypeDefinition',
	kind: string,
	loc: Location?,
	operation: OperationTypeNode,
	type: NamedTypeNode,
}

-- // Type Definition

export type TypeDefinitionNode = any -- ROBLOX FIXME: implement type
	| ScalarTypeDefinitionNode
	| ObjectTypeDefinitionNode
	| InterfaceTypeDefinitionNode
	| UnionTypeDefinitionNode
	| EnumTypeDefinitionNode
	| InputObjectTypeDefinitionNode

export type ScalarTypeDefinitionNode = {
	-- kind: 'ScalarTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
}

export type ObjectTypeDefinitionNode = {
	-- kind: 'ObjectTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	interfaces: Array<NamedTypeNode>?,
	directives: Array<DirectiveNode>?,
	fields: Array<FieldDefinitionNode>?,
}

export type FieldDefinitionNode = {
	-- kind: 'FieldDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	arguments: Array<InputValueDefinitionNode>?,
	type: TypeNode,
	directives: Array<DirectiveNode>?,
}

export type InputValueDefinitionNode = {
	-- kind: 'InputValueDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	type: TypeNode,
	defaultValue: ValueNode?,
	directives: Array<DirectiveNode>?,
}

export type InterfaceTypeDefinitionNode = {
	-- kind: 'InterfaceTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	interfaces: Array<NamedTypeNode>?,
	directives: Array<DirectiveNode>?,
	fields: Array<FieldDefinitionNode>?,
}

export type UnionTypeDefinitionNode = {
	-- kind: 'UnionTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	types: Array<NamedTypeNode>?,
}

export type EnumTypeDefinitionNode = {
	-- kind: 'EnumTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	values: Array<EnumValueDefinitionNode>?,
}

export type EnumValueDefinitionNode = {
	-- kind: 'EnumValueDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
}

export type InputObjectTypeDefinitionNode = {
	-- kind: 'InputObjectTypeDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	fields: Array<InputValueDefinitionNode>?,
}

-- // Directive Definitions
-- ...

export type DirectiveDefinitionNode = {
	-- kind: 'DirectiveDefinition',
	kind: string,
	loc: Location?,
	description: StringValueNode?,
	name: NameNode,
	arguments: Array<InputValueDefinitionNode>?,
	repeatable: boolean,
	locations: Array<NameNode>,
}

-- // Type System Extensions

export type TypeSystemExtensionNode = SchemaExtensionNode | TypeExtensionNode;

export type SchemaExtensionNode = {
	-- kind: 'SchemaExtension',
	kind: string,
	loc: Location?,
	directives: Array<DirectiveNode>?,
	operationTypes: Array<OperationTypeDefinitionNode>?,
}

-- // Type Extensions
export type TypeExtensionNode =
	ScalarTypeExtensionNode
	| ObjectTypeExtensionNode
	| InterfaceTypeExtensionNode
	| UnionTypeExtensionNode
	| EnumTypeExtensionNode
	| InputObjectTypeExtensionNode

export type ScalarTypeExtensionNode = {
	-- kind: 'ScalarTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
}

export type ObjectTypeExtensionNode = {
	-- kind: 'ObjectTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	interfaces: Array<NamedTypeNode>?,
	directives: Array<DirectiveNode>?,
	fields: Array<FieldDefinitionNode>?,
}

export type InterfaceTypeExtensionNode = {
	-- kind: 'InterfaceTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	interfaces: Array<NamedTypeNode>?,
	directives: Array<DirectiveNode>?,
	fields: Array<FieldDefinitionNode>?,
}

export type UnionTypeExtensionNode = {
	-- kind: 'UnionTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	types: Array<NamedTypeNode>?,
}

export type EnumTypeExtensionNode = {
	-- kind: 'EnumTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	values: Array<EnumValueDefinitionNode>?,
}

export type InputObjectTypeExtensionNode = {
	-- kind: 'InputObjectTypeExtension',
	kind: string,
	loc: Location?,
	name: NameNode,
	directives: Array<DirectiveNode>?,
	fields: Array<InputValueDefinitionNode>?,
}

return {
	Location = Location,
	Token = Token,
	isNode = isNode,
}
