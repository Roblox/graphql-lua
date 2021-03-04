-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/language/index.js

local locationModule = require(script.location)
local printLocationModule = require(script.printLocation)
local kindsModule = require(script.kinds)
local tokenKindModule = require(script.tokenKind)
local parserModule = require(script.parser)
local visitorModule = require(script.visitor)
local astModule = require(script.ast)
local predicatesModule = require(script.predicates)
local directiveLocationModule = require(script.directiveLocation)

export type SourceLocation = locationModule.SourceLocation

export type KindEnum = kindsModule.KindEnum

export type TokenKindEnum = tokenKindModule.TokenKindEnum

export type ParseOptions = parserModule.ParseOptions

-- ROBLOX FIXME: add types
export type ASTVisitor = any -- visitorModule.ASTVisitor
export type Visitor = any -- visitorModule.Visitor
export type VisitFn = any -- visitorModule.VisitFn
export type VisitorKeyMap = any -- visitorModule.VisitorKeyMap


export type ASTNode = astModule.ASTNode
export type ASTKindToNode = astModule.ASTKindToNode
-- Each kind of AST node
export type NameNode = astModule.NameNode
export type DocumentNode = astModule.DocumentNode
export type DefinitionNode = astModule.DefinitionNode
export type ExecutableDefinitionNode = astModule.ExecutableDefinitionNode
export type OperationDefinitionNode = astModule.OperationDefinitionNode
export type OperationTypeNode = astModule.OperationTypeNode
export type VariableDefinitionNode = astModule.VariableDefinitionNode
export type VariableNode = astModule.VariableNode
export type SelectionSetNode = astModule.SelectionSetNode
export type SelectionNode = astModule.SelectionNode
export type FieldNode = astModule.FieldNode
export type ArgumentNode = astModule.ArgumentNode
export type FragmentSpreadNode = astModule.FragmentSpreadNode
export type InlineFragmentNode = astModule.InlineFragmentNode
export type FragmentDefinitionNode = astModule.FragmentDefinitionNode
export type ValueNode = astModule.ValueNode
export type IntValueNode = astModule.IntValueNode
export type FloatValueNode = astModule.FloatValueNode
export type StringValueNode = astModule.StringValueNode
export type BooleanValueNode = astModule.BooleanValueNode
export type NullValueNode = astModule.NullValueNode
export type EnumValueNode = astModule.EnumValueNode
export type ListValueNode = astModule.ListValueNode
export type ObjectValueNode = astModule.ObjectValueNode
export type ObjectFieldNode = astModule.ObjectFieldNode
export type DirectiveNode = astModule.DirectiveNode
export type TypeNode = astModule.TypeNode
export type NamedTypeNode = astModule.NamedTypeNode
export type ListTypeNode = astModule.ListTypeNode
export type NonNullTypeNode = astModule.NonNullTypeNode
export type TypeSystemDefinitionNode = astModule.TypeSystemDefinitionNode
export type SchemaDefinitionNode = astModule.SchemaDefinitionNode
export type OperationTypeDefinitionNode = astModule.OperationTypeDefinitionNode
export type TypeDefinitionNode = astModule.TypeDefinitionNode
export type ScalarTypeDefinitionNode = astModule.ScalarTypeDefinitionNode
export type ObjectTypeDefinitionNode = astModule.ObjectTypeDefinitionNode
export type FieldDefinitionNode = astModule.FieldDefinitionNode
export type InputValueDefinitionNode = astModule.InputValueDefinitionNode
export type InterfaceTypeDefinitionNode = astModule.InterfaceTypeDefinitionNode
export type UnionTypeDefinitionNode = astModule.UnionTypeDefinitionNode
export type EnumTypeDefinitionNode = astModule.EnumTypeDefinitionNode
export type EnumValueDefinitionNode = astModule.EnumValueDefinitionNode
export type InputObjectTypeDefinitionNode = astModule.InputObjectTypeDefinitionNode
export type DirectiveDefinitionNode = astModule.DirectiveDefinitionNode
export type TypeSystemExtensionNode = astModule.TypeSystemExtensionNode
export type SchemaExtensionNode = astModule.SchemaExtensionNode
export type TypeExtensionNode = astModule.TypeExtensionNode
export type ScalarTypeExtensionNode = astModule.ScalarTypeExtensionNode
export type ObjectTypeExtensionNode = astModule.ObjectTypeExtensionNode
export type InterfaceTypeExtensionNode = astModule.InterfaceTypeExtensionNode
export type UnionTypeExtensionNode = astModule.UnionTypeExtensionNode
export type EnumTypeExtensionNode = astModule.EnumTypeExtensionNode
export type InputObjectTypeExtensionNode = astModule.InputObjectTypeExtensionNode

export type DirectiveLocationEnum = directiveLocationModule.DirectiveLocationEnum

return {
	Source = require(script.source).Source,
	getLocation = locationModule.getLocation,
	printLocation = printLocationModule.printLocation,
	printSourceLocation = printLocationModule.printSourceLocation,
	Kind = kindsModule.Kind,
	TokenKind = tokenKindModule.TokenKind,
	Lexer = require(script.lexer).Lexer,
	parse = parserModule.parse,
	parseValue = parserModule.parseValue,
	parseType = parserModule.parseType,
	print = require(script.printer).print,
	visit = visitorModule.visit,
	visitInParallel = visitorModule.visitInParallel,
	getVisitFn = visitorModule.getVisitFn,
	BREAK = visitorModule.BREAK,
	REMOVE = visitorModule.REMOVE, -- ROBLOX deviation - instead of null for removing node we use this token
	Location = astModule.Location,
	Token = astModule.Token,
	isDefinitionNode = predicatesModule.isDefinitionNode,
	isExecutableDefinitionNode = predicatesModule.isExecutableDefinitionNode,
	isSelectionNode = predicatesModule.isSelectionNode,
	isValueNode = predicatesModule.isValueNode,
	isTypeNode = predicatesModule.isTypeNode,
	isTypeSystemDefinitionNode = predicatesModule.isTypeSystemDefinitionNode,
	isTypeDefinitionNode = predicatesModule.isTypeDefinitionNode,
	isTypeSystemExtensionNode = predicatesModule.isTypeSystemExtensionNode,
	isTypeExtensionNode = predicatesModule.isTypeExtensionNode,
	DirectiveLocation = directiveLocationModule.DirectiveLocation,
}
