-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/kinds.js

local exports = {}

exports.Kind = {
	-- Name
	NAME = "Name",

	-- Document
	DOCUMENT = "Document",
	OPERATION_DEFINITION = "OperationDefinition",
	VARIABLE_DEFINITION = "VariableDefinition",
	SELECTION_SET = "SelectionSet",
	FIELD = "Field",
	ARGUMENT = "Argument",

	-- Fragments
	FRAGMENT_SPREAD = "FragmentSpread",
	INLINE_FRAGMENT = "InlineFragment",
	FRAGMENT_DEFINITION = "FragmentDefinition",

	-- Values
	VARIABLE = "Variable",
	INT = "IntValue",
	FLOAT = "FloatValue",
	STRING = "StringValue",
	BOOLEAN = "BooleanValue",
	NULL = "NullValue",
	ENUM = "EnumValue",
	LIST = "ListValue",
	OBJECT = "ObjectValue",
	OBJECT_FIELD = "ObjectField",

	-- Directives
	DIRECTIVE = "Directive",

	-- Types
	NAMED_TYPE = "NamedType",
	LIST_TYPE = "ListType",
	NON_NULL_TYPE = "NonNullType",

	-- Type System Definitions
	SCHEMA_DEFINITION = "SchemaDefinition",
	OPERATION_TYPE_DEFINITION = "OperationTypeDefinition",

	-- Type Definitions
	SCALAR_TYPE_DEFINITION = "ScalarTypeDefinition",
	OBJECT_TYPE_DEFINITION = "ObjectTypeDefinition",
	FIELD_DEFINITION = "FieldDefinition",
	INPUT_VALUE_DEFINITION = "InputValueDefinition",
	INTERFACE_TYPE_DEFINITION = "InterfaceTypeDefinition",
	UNION_TYPE_DEFINITION = "UnionTypeDefinition",
	ENUM_TYPE_DEFINITION = "EnumTypeDefinition",
	ENUM_VALUE_DEFINITION = "EnumValueDefinition",
	INPUT_OBJECT_TYPE_DEFINITION = "InputObjectTypeDefinition",

	-- Directive Definitions
	DIRECTIVE_DEFINITION = "DirectiveDefinition",

	-- Type System Extensions
	SCHEMA_EXTENSION = "SchemaExtension",

	-- Type Extensions
	SCALAR_TYPE_EXTENSION = "ScalarTypeExtension",
	OBJECT_TYPE_EXTENSION = "ObjectTypeExtension",
	INTERFACE_TYPE_EXTENSION = "InterfaceTypeExtension",
	UNION_TYPE_EXTENSION = "UnionTypeExtension",
	ENUM_TYPE_EXTENSION = "EnumTypeExtension",
	INPUT_OBJECT_TYPE_EXTENSION = "InputObjectTypeExtension",
}

return exports