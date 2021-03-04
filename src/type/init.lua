-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/type/index.js

local exports = {}

local PathModule = require(script.Parent.jsutils.Path)
export type ResponsePath = PathModule.Path


local schemaModule = require(script.schema)
-- Predicate
exports.isSchema = schemaModule.isSchema
-- Assertion
exports.assertSchema = schemaModule.assertSchema
-- GraphQL Schema definition
exports.GraphQLSchema = schemaModule.GraphQLSchema

export type GraphQLSchemaConfig = schemaModule.GraphQLSchemaConfig


local definitionModule = require(script.definition)
-- Predicates
exports.isType = definitionModule.isType
exports.isScalarType = definitionModule.isScalarType
exports.isObjectType = definitionModule.isObjectType
exports.isInterfaceType = definitionModule.isInterfaceType
exports.isUnionType = definitionModule.isUnionType
exports.isEnumType = definitionModule.isEnumType
exports.isInputObjectType = definitionModule.isInputObjectType
exports.isListType = definitionModule.isListType
exports.isNonNullType = definitionModule.isNonNullType
exports.isInputType = definitionModule.isInputType
exports.isOutputType = definitionModule.isOutputType
exports.isLeafType = definitionModule.isLeafType
exports.isCompositeType = definitionModule.isCompositeType
exports.isAbstractType = definitionModule.isAbstractType
exports.isWrappingType = definitionModule.isWrappingType
exports.isNullableType = definitionModule.isNullableType
exports.isNamedType = definitionModule.isNamedType
exports.isRequiredArgument = definitionModule.isRequiredArgument
exports.isRequiredInputField = definitionModule.isRequiredInputField
-- Assertions
exports.assertType = definitionModule.assertType
exports.assertScalarType = definitionModule.assertScalarType
exports.assertObjectType = definitionModule.assertObjectType
exports.assertInterfaceType = definitionModule.assertInterfaceType
exports.assertUnionType = definitionModule.assertUnionType
exports.assertEnumType = definitionModule.assertEnumType
exports.assertInputObjectType = definitionModule.assertInputObjectType
exports.assertListType = definitionModule.assertListType
exports.assertNonNullType = definitionModule.assertNonNullType
exports.assertInputType = definitionModule.assertInputType
exports.assertOutputType = definitionModule.assertOutputType
exports.assertLeafType = definitionModule.assertLeafType
exports.assertCompositeType = definitionModule.assertCompositeType
exports.assertAbstractType = definitionModule.assertAbstractType
exports.assertWrappingType = definitionModule.assertWrappingType
exports.assertNullableType = definitionModule.assertNullableType
exports.assertNamedType = definitionModule.assertNamedType
-- Un-modifiers
exports.getNullableType = definitionModule.getNullableType
exports.getNamedType = definitionModule.getNamedType
-- Definitions
exports.GraphQLScalarType = definitionModule.GraphQLScalarType
exports.GraphQLObjectType = definitionModule.GraphQLObjectType
exports.GraphQLInterfaceType = definitionModule.GraphQLInterfaceType
exports.GraphQLUnionType = definitionModule.GraphQLUnionType
exports.GraphQLEnumType = definitionModule.GraphQLEnumType
exports.GraphQLInputObjectType = definitionModule.GraphQLInputObjectType
-- Type Wrappers
exports.GraphQLList = definitionModule.GraphQLList
exports.GraphQLNonNull = definitionModule.GraphQLNonNull


local directivesModule = require(script.directives)

-- Predicate
exports.isDirective = directivesModule.isDirective
-- Assertion
exports.assertDirective = directivesModule.assertDirective
-- Directives Definition
exports.GraphQLDirective = directivesModule.GraphQLDirective
-- Built-in Directives defined by the Spec
exports.isSpecifiedDirective = directivesModule.isSpecifiedDirective
exports.specifiedDirectives = directivesModule.specifiedDirectives
exports.GraphQLIncludeDirective = directivesModule.GraphQLIncludeDirective
exports.GraphQLSkipDirective = directivesModule.GraphQLSkipDirective
exports.GraphQLDeprecatedDirective = directivesModule.GraphQLDeprecatedDirective
exports.GraphQLSpecifiedByDirective = directivesModule.GraphQLSpecifiedByDirective
-- Constant Deprecation Reason
exports.DEFAULT_DEPRECATION_REASON = directivesModule.DEFAULT_DEPRECATION_REASON

-- ROBLOX deviation: add types
export type GraphQLDirectiveConfig = any -- directivesModule.GraphQLDirectiveConfig

-- Common built-in scalar instances.
local scalarsModule = require(script.scalars)

-- Predicate
exports.isSpecifiedScalarType = scalarsModule.isSpecifiedScalarType
-- Standard GraphQL Scalars
exports.specifiedScalarTypes = scalarsModule.specifiedScalarTypes
exports.GraphQLInt = scalarsModule.GraphQLInt
exports.GraphQLFloat = scalarsModule.GraphQLFloat
exports.GraphQLString = scalarsModule.GraphQLString
exports.GraphQLBoolean = scalarsModule.GraphQLBoolean
exports.GraphQLID = scalarsModule.GraphQLID

local introspectionModule = require(script.introspection)

-- Predicate
exports.isIntrospectionType = introspectionModule.isIntrospectionType
-- GraphQL Types for introspection.
exports.introspectionTypes = introspectionModule.introspectionTypes
exports.__Schema = introspectionModule.__Schema
exports.__Directive = introspectionModule.__Directive
exports.__DirectiveLocation = introspectionModule.__DirectiveLocation
exports.__Type = introspectionModule.__Type
exports.__Field = introspectionModule.__Field
exports.__InputValue = introspectionModule.__InputValue
exports.__EnumValue = introspectionModule.__EnumValue
exports.__TypeKind = introspectionModule.__TypeKind
-- "Enum" of Type Kinds
exports.TypeKind = introspectionModule.TypeKind
-- Meta-field definitions.
exports.SchemaMetaFieldDef = introspectionModule.SchemaMetaFieldDef
exports.TypeMetaFieldDef = introspectionModule.TypeMetaFieldDef
exports.TypeNameMetaFieldDef = introspectionModule.TypeNameMetaFieldDef


-- ROBLOX deviation: add types
export type GraphQLType = any -- definitionModule.GraphQLType
export type GraphQLInputType = any -- definitionModule.GraphQLInputType
export type GraphQLOutputType = any -- definitionModule.GraphQLOutputType
export type GraphQLLeafType = any -- definitionModule.GraphQLLeafType
export type GraphQLCompositeType = any -- definitionModule.GraphQLCompositeType
export type GraphQLAbstractType = any -- definitionModule.GraphQLAbstractType
export type GraphQLWrappingType = any -- definitionModule.GraphQLWrappingType
export type GraphQLNullableType = any -- definitionModule.GraphQLNullableType
export type GraphQLNamedType = any -- definitionModule.GraphQLNamedType
export type Thunk = any -- definitionModule.Thunk
export type GraphQLArgument = any -- definitionModule.GraphQLArgument
export type GraphQLArgumentConfig = any -- definitionModule.GraphQLArgumentConfig
export type GraphQLEnumTypeConfig = any -- definitionModule.GraphQLEnumTypeConfig
export type GraphQLEnumValue = any -- definitionModule.GraphQLEnumValue
export type GraphQLEnumValueConfig = any -- definitionModule.GraphQLEnumValueConfig
export type GraphQLEnumValueConfigMap = any -- definitionModule.GraphQLEnumValueConfigMap
export type GraphQLField = any -- definitionModule.GraphQLField
export type GraphQLFieldConfig = any -- definitionModule.GraphQLFieldConfig
export type GraphQLFieldConfigArgumentMap = any -- definitionModule.GraphQLFieldConfigArgumentMap
export type GraphQLFieldConfigMap = any -- definitionModule.GraphQLFieldConfigMap
export type GraphQLFieldMap = any -- definitionModule.GraphQLFieldMap
export type GraphQLFieldResolver = any -- definitionModule.GraphQLFieldResolver
export type GraphQLInputField = any -- definitionModule.GraphQLInputField
export type GraphQLInputFieldConfig = any -- definitionModule.GraphQLInputFieldConfig
export type GraphQLInputFieldConfigMap = any -- definitionModule.GraphQLInputFieldConfigMap
export type GraphQLInputFieldMap = any -- definitionModule.GraphQLInputFieldMap
export type GraphQLInputObjectTypeConfig = any -- definitionModule.GraphQLInputObjectTypeConfig
export type GraphQLInterfaceTypeConfig = any -- definitionModule.GraphQLInterfaceTypeConfig
export type GraphQLIsTypeOfFn = any -- definitionModule.GraphQLIsTypeOfFn
export type GraphQLObjectTypeConfig = any -- definitionModule.GraphQLObjectTypeConfig
export type GraphQLResolveInfo = any -- definitionModule.GraphQLResolveInfo
export type GraphQLScalarTypeConfig = any -- definitionModule.GraphQLScalarTypeConfig
export type GraphQLTypeResolver = any -- definitionModule.GraphQLTypeResolver
export type GraphQLUnionTypeConfig = any -- definitionModule.GraphQLUnionTypeConfig
export type GraphQLScalarSerializer = any -- definitionModule.GraphQLScalarSerializer
export type GraphQLScalarValueParser = any -- definitionModule.GraphQLScalarValueParser
export type GraphQLScalarLiteralParser = any -- definitionModule.GraphQLScalarLiteralParser

-- Validate GraphQL schema.
local validateModule = require(script.validate)

exports.validateSchema = validateModule.validateSchema
exports.assertValidSchema = validateModule.assertValidSchema

return exports
