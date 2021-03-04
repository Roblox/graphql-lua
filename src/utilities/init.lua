-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/index.js

local getIntrospectionQueryModule = require(script.getIntrospectionQuery)
local buildASTSchemaModule = require(script.buildASTSchema)
local printSchemaModule = require(script.printSchema)
local TypeInfoModule = require(script.TypeInfo)
local typeComparatorsModule = require(script.typeComparators)
local assertValidNameModule = require(script.assertValidName)
local findBreakingChangesModule = require(script.findBreakingChanges)

-- ROBLOX deviation: add types
export type IntrospectionOptions = any -- getIntrospectionQueryModule.IntrospectionOptions
export type IntrospectionQuery = any -- getIntrospectionQueryModule.IntrospectionQuery
export type IntrospectionSchema = any -- getIntrospectionQueryModule.IntrospectionSchema
export type IntrospectionType = any -- getIntrospectionQueryModule.IntrospectionType
export type IntrospectionInputType = any -- getIntrospectionQueryModule.IntrospectionInputType
export type IntrospectionOutputType = any -- getIntrospectionQueryModule.IntrospectionOutputType
export type IntrospectionScalarType = any -- getIntrospectionQueryModule.IntrospectionScalarType
export type IntrospectionObjectType = any -- getIntrospectionQueryModule.IntrospectionObjectType
export type IntrospectionInterfaceType = any -- getIntrospectionQueryModule.IntrospectionInterfaceType
export type IntrospectionUnionType = any -- getIntrospectionQueryModule.IntrospectionUnionType
export type IntrospectionEnumType = any -- getIntrospectionQueryModule.IntrospectionEnumType
export type IntrospectionInputObjectType = any -- getIntrospectionQueryModule.IntrospectionInputObjectType
export type IntrospectionTypeRef = any -- getIntrospectionQueryModule.IntrospectionTypeRef
export type IntrospectionInputTypeRef = any -- getIntrospectionQueryModule.IntrospectionInputTypeRef
export type IntrospectionOutputTypeRef = any -- getIntrospectionQueryModule.IntrospectionOutputTypeRef
export type IntrospectionNamedTypeRef = any -- getIntrospectionQueryModule.IntrospectionNamedTypeRef
export type IntrospectionListTypeRef = any -- getIntrospectionQueryModule.IntrospectionListTypeRef
export type IntrospectionNonNullTypeRef = any -- getIntrospectionQueryModule.IntrospectionNonNullTypeRef
export type IntrospectionField = any -- getIntrospectionQueryModule.IntrospectionField
export type IntrospectionInputValue = any -- getIntrospectionQueryModule.IntrospectionInputValue
export type IntrospectionEnumValue = any -- getIntrospectionQueryModule.IntrospectionEnumValue
export type IntrospectionDirective = any -- getIntrospectionQueryModule.IntrospectionDirective

export type BuildSchemaOptions = any -- buildASTSchemaModule.BuildSchemaOptions

export type BreakingChange = any -- findBreakingChangesModule.BreakingChange
export type DangerousChange = any -- findBreakingChangesModule.DangerousChange

return {
	-- Produce the GraphQL query recommended for a full schema introspection.
	-- Accepts optional IntrospectionOptions.
	getIntrospectionQuery = getIntrospectionQueryModule.getIntrospectionQuery,

	-- Gets the target Operation from a Document.
	getOperationAST = require(script.getOperationAST).getOperationAST,

	-- Gets the Type for the target Operation AST.
	getOperationRootType = require(script.getOperationRootType).getOperationRootType,

	-- Convert a GraphQLSchema to an IntrospectionQuery.
	introspectionFromSchema =  require(script.introspectionFromSchema).introspectionFromSchema,

	-- Build a GraphQLSchema from an introspection result.
	buildClientSchema = require(script.buildClientSchema).buildClientSchema,

	-- Build a GraphQLSchema from GraphQL Schema language.
	buildASTSchema = buildASTSchemaModule.buildASTSchema,
	buildSchema = buildASTSchemaModule.buildSchema,

	-- Extends an existing GraphQLSchema from a parsed GraphQL Schema language AST.
	extendSchema = require(script.extendSchema).extendSchema,

	-- Sort a GraphQLSchema.
	lexicographicSortSchema = require(script.lexicographicSortSchema).lexicographicSortSchema,

	-- Print a GraphQLSchema to GraphQL Schema language.
	printSchema = printSchemaModule.printSchema,
	printType = printSchemaModule.printType,
	printIntrospectionSchema = printSchemaModule.printIntrospectionSchema,

	-- Create a GraphQLType from a GraphQL language AST.
	typeFromAST = require(script.typeFromAST).typeFromAST,

	-- Create a JavaScript value from a GraphQL language AST with a type.
	valueFromAST = require(script.valueFromAST).valueFromAST,

	-- Create a JavaScript value from a GraphQL language AST without a type.
	valueFromASTUntyped = require(script.valueFromASTUntyped).valueFromASTUntyped,

	-- Create a GraphQL language AST from a JavaScript value.
	astFromValue = require(script.astFromValue).astFromValue,

	-- A helper to use within recursive-descent visitors which need to be aware of
	-- the GraphQL type system.
	TypeInfo = TypeInfoModule.TypeInfo,
	visitWithTypeInfo = TypeInfoModule.visitWithTypeInfo,

	-- Coerces a JavaScript value to a GraphQL type, or produces errors.
	coerceInputValue = require(script.coerceInputValue).coerceInputValue,

	-- Concatenates multiple AST together.
	concatAST = require(script.concatAST).concatAST,

	-- Separates an AST into an AST per Operation.
	separateOperations = require(script.separateOperations).separateOperations,

	-- Strips characters that are not significant to the validity or execution
	-- of a GraphQL document.
	stripIgnoredCharacters = require(script.stripIgnoredCharacters).stripIgnoredCharacters,

	-- Comparators for types
	isEqualType = typeComparatorsModule.isEqualType,
	isTypeSubTypeOf = typeComparatorsModule.isTypeSubTypeOf,
	doTypesOverlap = typeComparatorsModule.doTypesOverlap,

	-- Asserts that a string is a valid GraphQL name
	assertValidName = assertValidNameModule.assertValidName,
	isValidNameError = assertValidNameModule.isValidNameError,

	-- Compares two GraphQLSchemas and detects breaking changes.
	BreakingChangeType = findBreakingChangesModule.BreakingChangeType,
	DangerousChangeType = findBreakingChangesModule.DangerousChangeType,
	findBreakingChanges = findBreakingChangesModule.findBreakingChanges,
	findDangerousChanges = findBreakingChangesModule.findDangerousChanges,

}
