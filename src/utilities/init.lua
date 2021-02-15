-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/index.js

local buildASTSchemaImport = require(script.buildASTSchema)
local printSchemaImport = require(script.printSchema)
local TypeInfoImport = require(script.TypeInfo)
local typeComparatorsImport = require(script.typeComparators)
local assertValidNameImport = require(script.assertValidName)

-- ROBLOX TODO - add implementation
local findBreakingChangesImport = {
	BreakingChangeType = {},
	DangerousChangeType = {},
	findBreakingChanges = function()--[[...]]
	end,
	findDangerousChanges = function()--[[...]]
	end,
}

return {
	-- Produce the GraphQL query recommended for a full schema introspection.
	-- Accepts optional IntrospectionOptions.
	getIntrospectionQuery = require(script.getIntrospectionQuery).getIntrospectionQuery,

	-- Gets the target Operation from a Document.
	getOperationAST = require(script.getOperationAST).getOperationAST,

	-- Gets the Type for the target Operation AST.
	getOperationRootType = require(script.getOperationRootType).getOperationRootType,

	-- Convert a GraphQLSchema to an IntrospectionQuery.
	-- ROBLOX TODO - add implementation
	introspectionFromSchema = function()--[[...]]
	end,

	-- Build a GraphQLSchema from an introspection result.
	buildClientSchema = require(script.buildClientSchema).buildClientSchema,

	-- Build a GraphQLSchema from GraphQL Schema language.
	buildASTSchema = buildASTSchemaImport.buildASTSchema,
	buildSchema = buildASTSchemaImport.buildSchema,

	-- Extends an existing GraphQLSchema from a parsed GraphQL Schema language AST.
	extendSchema = require(script.extendSchema).extendSchema,

	-- Sort a GraphQLSchema.
	-- ROBLOX TODO - add implementation
	lexicographicSortSchema = function()--[[...]]
	end,

	-- Print a GraphQLSchema to GraphQL Schema language.
	printSchema = printSchemaImport.printSchema,
	printType = printSchemaImport.printType,
	printIntrospectionSchema = printSchemaImport.printIntrospectionSchema,

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
	TypeInfo = TypeInfoImport.TypeInfo,
	visitWithTypeInfo = TypeInfoImport.visitWithTypeInfo,

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
	isEqualType = typeComparatorsImport.isEqualType,
	isTypeSubTypeOf = typeComparatorsImport.isTypeSubTypeOf,
	doTypesOverlap = typeComparatorsImport.doTypesOverlap,

	-- Asserts that a string is a valid GraphQL name
	assertValidName = assertValidNameImport.assertValidName,
	isValidNameError = assertValidNameImport.isValidNameError,

	-- Compares two GraphQLSchemas and detects breaking changes.
	BreakingChangeType = findBreakingChangesImport.BreakingChangeType,
	DangerousChangeType = findBreakingChangesImport.DangerousChangeType,
	findBreakingChanges = findBreakingChangesImport.findBreakingChanges,
	findDangerousChanges = findBreakingChangesImport.findDangerousChanges,

}
