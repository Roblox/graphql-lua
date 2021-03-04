-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/parser.js
type Array<T> = { [number]: T }

local language = script.Parent

local Location = require(language.ast).Location

local sourceModule = require(language.source)
local Source = sourceModule.Source

local lexer = require(language.lexer)
local Lexer = lexer.Lexer
local isPunctuatorTokenKind = lexer.isPunctuatorTokenKind

local TokenKind = require(language.tokenKind).TokenKind
local DirectiveLocation = require(language.directiveLocation).DirectiveLocation
local Kind = require(language.kinds).Kind

local syntaxError = require(script.Parent.Parent.error.syntaxError).syntaxError

--[[
 * Configuration options to control parser behavior
 *]]
export type ParseOptions = {
  --[[/**
   * By default, the parser creates AST nodes that know the location
   * in the source that they correspond to. This configuration flag
   * disables that behavior for performance or testing.
   */
  ]]
  noLocation: boolean?,
  --[[
   * EXPERIMENTAL:
   *
   * If enabled, the parser will understand and parse variable definitions
   * contained in a fragment definition. They'll be represented in the
   * `variableDefinitions` field of the FragmentDefinitionNode.
   *
   * The syntax is identical to normal, query-defined variables. For example:
   *
   *   fragment A($var: Boolean = false) on T  {
   *     ...
   *   }
   *
   * Note: this feature is experimental and may change or be removed in the
   * future.
   *]]
  experimentalFragmentVariables: boolean?
}


-- deviation: pre-declare functions
local getTokenDesc
local getTokenKindDesc

local Parser = {}
Parser.__index = Parser

--[[*
--  * Given a GraphQL source, parses it into a Document.
--  * Throws GraphQLError if a syntax error is encountered.
--  *]]
local function parse(source, options)
	local parser = Parser.new(source, options)
	return parser:parseDocument()
end

--[[
--  * Given a string containing a GraphQL value (ex. `[42]`), parse the AST for
--  * that value.
--  * Throws GraphQLError if a syntax error is encountered.
--  *
--  * This is useful within tools that operate upon GraphQL Values directly and
--  * in isolation of complete GraphQL documents.
--  *
--  * Consider providing the results to the utility function: valueFromAST().
]]
local function parseValue(source, options)
	local parser = Parser.new(source, options)
	parser:expectToken(TokenKind.SOF)
	local value = parser:parseValueLiteral(false)
	parser:expectToken(TokenKind.EOF)
	return value
end

--[[*
--  * Given a string containing a GraphQL Type (ex. `[Int!]`), parse the AST for
--  * that type.
--  * Throws GraphQLError if a syntax error is encountered.
--  *
--  * This is useful within tools that operate upon GraphQL Types directly and
--  * in isolation of complete GraphQL documents.
--  *
--  * Consider providing the results to the utility function: typeFromAST().
--  *]]
local function parseType(source, options)
	local parser = Parser.new(source, options)
	parser:expectToken(TokenKind.SOF)
	local type_ = parser:parseTypeReference()
	parser:expectToken(TokenKind.EOF)
	return type_
end

function Parser.new(source, options)
	local sourceObj
	if typeof(source) == "string" then
		sourceObj = Source.new(source)
	else
		sourceObj = source
	end

	local self = {}
	self._lexer = Lexer.new(sourceObj)
	self._options = options

	return setmetatable(self, Parser)
end

--[[*
--  * Converts a name lex token into a name parse node.
--  *]]
function Parser:parseName()
	local token = self:expectToken(TokenKind.NAME)
	return {
		kind = Kind.NAME,
		value = token.value,
		loc = self:loc(token),
	}
end

-- Implements the parsing rules in the Document section.

--[[*
--  * Document : Definition+
--  *]]
function Parser:parseDocument()
	local start = self._lexer.token
	return {
		kind = Kind.DOCUMENT,
		definitions = self:many(TokenKind.SOF, self.parseDefinition, TokenKind.EOF),
		loc = self:loc(start),
	}
end

--[[*
--  * Definition :
--  *   - ExecutableDefinition
--  *   - TypeSystemDefinition
--  *   - TypeSystemExtension
--  *
--  * ExecutableDefinition :
--  *   - OperationDefinition
--  *   - FragmentDefinition
--  *]]
function Parser:parseDefinition()
	if self:peek(TokenKind.NAME) then
		local tokenValue = self._lexer.token.value
		if tokenValue == "query" or tokenValue == "mutation" or tokenValue == "subscription" then
			return self:parseOperationDefinition()
		elseif tokenValue == "fragment" then
			return self:parseFragmentDefinition()
		elseif
			tokenValue == "schema"
			or tokenValue == "scalar"
			or tokenValue == "type"
			or tokenValue == "interface"
			or tokenValue == "union"
			or tokenValue == "enum"
			or tokenValue == "input"
			or tokenValue == "directive"
		then
			return self:parseTypeSystemDefinition()
		elseif tokenValue == "extend" then
			return self:parseTypeSystemExtension()
		end
	elseif self:peek(TokenKind.BRACE_L) then
		return self:parseOperationDefinition()
	elseif self:peekDescription() then
		return self:parseTypeSystemDefinition()
	end

	error(self:unexpected())
end

-- Implements the parsing rules in the Operations section.

--[[*
--  * OperationDefinition :
--  *  - SelectionSet
--  *  - OperationType Name? VariableDefinitions? Directives? SelectionSet
--  *]]
function Parser:parseOperationDefinition()
	local start = self._lexer.token
	if self:peek(TokenKind.BRACE_L) then
		return {
			kind = Kind.OPERATION_DEFINITION,
			operation = "query",
			name = nil,
			variableDefinitions = {},
			directives = {},
			selectionSet = self:parseSelectionSet(),
			loc = self:loc(start),
		}
	end
	local operation = self:parseOperationType()
	local name
	if self:peek(TokenKind.NAME) then
		name = self:parseName()
	end
	return {
		kind = Kind.OPERATION_DEFINITION,
		operation = operation,
		name = name,
		variableDefinitions = self:parseVariableDefinitions(),
		directives = self:parseDirectives(false),
		selectionSet = self:parseSelectionSet(),
		loc = self:loc(start),
	}
end

--[[*
--  * OperationType : one of query mutation subscription
--  *]]
function Parser:parseOperationType()
	local operationToken = self:expectToken(TokenKind.NAME)

	if operationToken.value == "query" then
		return "query"
	elseif operationToken.value == "mutation" then
		return "mutation"
	elseif operationToken.value == "subscription" then
		return "subscription"
	end

	error(self:unexpected(operationToken))
end

--[[*
--  * VariableDefinitions : ( VariableDefinition+ )
--  *]]
function Parser:parseVariableDefinitions()
	return self:optionalMany(TokenKind.PAREN_L, self.parseVariableDefinition, TokenKind.PAREN_R)
end

--[[*
--  * VariableDefinition : Variable : Type DefaultValue? Directives[Const]?
--  *]]
function Parser:parseVariableDefinition()
	local start = self._lexer.token
	return {
		kind = Kind.VARIABLE_DEFINITION,
		variable = self:parseVariable(),
		type = (function()
			self:expectToken(TokenKind.COLON)
			return self:parseTypeReference()
		end)(),
		defaultValue = (function()
			if self:expectOptionalToken(TokenKind.EQUALS) then
				return self:parseValueLiteral(true)
			else
				return nil
			end
		end)(),
		directives = self:parseDirectives(true),
		loc = self:loc(start),
	}
end

--[[*
--  * Variable : $ Name
--  *]]
function Parser:parseVariable()
	local start = self._lexer.token
	self:expectToken(TokenKind.DOLLAR)
	return {
		kind = Kind.VARIABLE,
		name = self:parseName(),
		loc = self:loc(start),
	}
end

--[[*
--  * SelectionSet : { Selection+ }
--  *]]
function Parser:parseSelectionSet()
	local start = self._lexer.token
	return {
		kind = Kind.SELECTION_SET,
		selections = self:many(TokenKind.BRACE_L, self.parseSelection, TokenKind.BRACE_R),
		loc = self:loc(start),
	}
end

--[[*
--  * Selection :
--  *   - Field
--  *   - FragmentSpread
--  *   - InlineFragment
--  *]]
function Parser:parseSelection()
	if self:peek(TokenKind.SPREAD) then
		return self:parseFragment()
	else
		return self:parseField()
	end
end

--[[*
--  * Field : Alias? Name Arguments? Directives? SelectionSet?
--  *
--  * Alias : Name :
--  *]]
function Parser:parseField()
	local start = self._lexer.token

	local nameOrAlias = self:parseName()
	local alias
	local name
	if self:expectOptionalToken(TokenKind.COLON) then
		alias = nameOrAlias
		name = self:parseName()
	else
		name = nameOrAlias
	end

	return {
		kind = Kind.FIELD,
		alias = alias,
		name = name,
		arguments = self:parseArguments(false),
		directives = self:parseDirectives(false),
		selectionSet = self:peek(TokenKind.BRACE_L) and self:parseSelectionSet() or nil,
		loc = self:loc(start),
	}
end

--[[*
--  * Arguments[Const] : ( Argument[?Const]+ )
--  *]]
function Parser:parseArguments(isConst)
	local item
	if isConst then
		item = self.parseConstArgument
	else
		item = self.parseArgument
	end
	return self:optionalMany(TokenKind.PAREN_L, item, TokenKind.PAREN_R)
end

--[[*
--  * Argument[Const] : Name : Value[?Const]
--  *]]
function Parser:parseArgument()
	local start = self._lexer.token
	local name = self:parseName()

	self:expectToken(TokenKind.COLON)
	return {
		kind = Kind.ARGUMENT,
		name = name,
		value = self:parseValueLiteral(false),
		loc = self:loc(start),
	}
end

function Parser:parseConstArgument()
	local start = self._lexer.token
	return {
		kind = Kind.ARGUMENT,
		name = self:parseName(),
		value = (function()
			self:expectToken(TokenKind.COLON)
			return self:parseValueLiteral(true)
		end)(),
		loc = self:loc(start),
	}
end

-- Implements the parsing rules in the Fragments section.

--[[*
--  * Corresponds to both FragmentSpread and InlineFragment in the spec.
--  *
--  * FragmentSpread : ... FragmentName Directives?
--  *
--  * InlineFragment : ... TypeCondition? Directives? SelectionSet
--  *]]
function Parser:parseFragment()
	local start = self._lexer.token
	self:expectToken(TokenKind.SPREAD)

	local hasTypeCondition = self:expectOptionalKeyword("on")
	if not hasTypeCondition and self:peek(TokenKind.NAME) then
		return {
			kind = Kind.FRAGMENT_SPREAD,
			name = self:parseFragmentName(),
			directives = self:parseDirectives(false),
			loc = self:loc(start),
		}
	end
	return {
		kind = Kind.INLINE_FRAGMENT,
		typeCondition = (function()
			if hasTypeCondition then
				return self:parseNamedType()
			else
				return nil
			end
		end)(),
		directives = self:parseDirectives(false),
		selectionSet = self:parseSelectionSet(),
		loc = self:loc(start),
	}
end

--[[*
--  * FragmentDefinition :
--  *   - fragment FragmentName on TypeCondition Directives? SelectionSet
--  *
--  * TypeCondition : NamedType
--  *]]
function Parser:parseFragmentDefinition()
	local start = self._lexer.token
	self:expectKeyword("fragment")
	-- Experimental support for defining variables within fragments changes
	-- the grammar of FragmentDefinition:
	--   - fragment FragmentName VariableDefinitions? on TypeCondition Directives? SelectionSet
	if (self._options and self._options.experimentalFragmentVariables) == true then
		local name = self:parseFragmentName()
		local variableDefinitions = self:parseVariableDefinitions()
		self:expectKeyword("on")
		local typeConditions = self:parseNamedType()
		local directives = self:parseDirectives(false)
		local selectionSet = self:parseSelectionSet()
		local loc = self:loc(start)
		return {
			kind = Kind.FRAGMENT_DEFINITION,
			name = name,
			variableDefinitions = variableDefinitions,
			typeCondition = typeConditions,
			directives = directives,
			selectionSet = selectionSet,
			loc = loc,
		}
	end
	local name = self:parseFragmentName()
	self:expectKeyword("on")
	local typeCondition = self:parseNamedType()
	local directives = self:parseDirectives(false)
	local selectionSet = self:parseSelectionSet()
	local loc = self:loc(start)
	return {
		kind = Kind.FRAGMENT_DEFINITION,
		name = name,
		typeCondition = typeCondition,
		directives = directives,
		selectionSet = selectionSet,
		loc = loc,
	}
end

--[[*
--  * FragmentName : Name but not `on`
--  *]]
function Parser:parseFragmentName()
	if self._lexer.token.value == "on" then
		error(self:unexpected())
	end
	return self:parseName()
end

-- Implements the parsing rules in the Values section.

--[[*
--  * Value[Const] :
--  *   - [~Const] Variable
--  *   - IntValue
--  *   - FloatValue
--  *   - StringValue
--  *   - BooleanValue
--  *   - NullValue
--  *   - EnumValue
--  *   - ListValue[?Const]
--  *   - ObjectValue[?Const]
--  *
--  * BooleanValue : one of `true` `false`
--  *
--  * NullValue : `null`
--  *
--  * EnumValue : Name but not `true`, `false` or `null`
--  *]]
function Parser:parseValueLiteral(isConst: boolean)
	local token = self._lexer.token

	local kind = token.kind
	if kind == TokenKind.BRACKET_L then
		return self:parseList(isConst)
	elseif kind == TokenKind.BRACE_L then
		return self:parseObject(isConst)
	elseif kind == TokenKind.INT then
		self._lexer:advance()
		return {
			kind = Kind.INT,
			value = token.value,
			loc = self:loc(token),
		}
	elseif kind == TokenKind.FLOAT then
		self._lexer:advance()
		return {
			kind = Kind.FLOAT,
			value = token.value,
			loc = self:loc(token),
		}
	elseif kind == TokenKind.STRING or kind == TokenKind.BLOCK_STRING then
		return self:parseStringLiteral()
	elseif kind == TokenKind.NAME then
		self._lexer:advance()
		local tokenValue = token.value
		if tokenValue == "true" then
			return { kind = Kind.BOOLEAN, value = true, loc = self:loc(token) }
		elseif tokenValue == "false" then
			return { kind = Kind.BOOLEAN, value = false, loc = self:loc(token) }
		elseif tokenValue == "null" then
			return { kind = Kind.NULL, loc = self:loc(token) }
		else
			return {
				kind = Kind.ENUM,
				value = tokenValue,
				loc = self:loc(token),
			}
		end
	elseif kind == TokenKind.DOLLAR then
		if not isConst then
			return self:parseVariable()
		end
		-- break
	end
	error(self:unexpected())
end

function Parser:parseStringLiteral()
	local token = self._lexer.token
	self._lexer:advance()
	return {
		kind = Kind.STRING,
		value = token.value,
		block = token.kind == TokenKind.BLOCK_STRING,
		loc = self:loc(token),
	}
end

--[[*
--  * ListValue[Const] :
--  *   - [ ]
--  *   - [ Value[?Const]+ ]
--  *]]
function Parser:parseList(isConst: boolean)
	local start = self._lexer.token
	local item = function()
		return self:parseValueLiteral(isConst)
	end
	return {
		kind = Kind.LIST,
		values = self:any(TokenKind.BRACKET_L, item, TokenKind.BRACKET_R),
		loc = self:loc(start),
	}
end

--[[*
--  * ObjectValue[Const] :
--  *   - { }
--  *   - { ObjectField[?Const]+ }
--  *]]
function Parser:parseObject(isConst: boolean)
	local start = self._lexer.token
	local item = function()
		return self:parseObjectField(isConst)
	end
	return {
		kind = Kind.OBJECT,
		fields = self:any(TokenKind.BRACE_L, item, TokenKind.BRACE_R),
		loc = self:loc(start),
	}
end

--[[*
--  * ObjectField[Const] : Name : Value[?Const]
--  *]]
function Parser:parseObjectField(isConst: boolean)
	local start = self._lexer.token
	local name = self:parseName()
	self:expectToken(TokenKind.COLON)

	return {
		kind = Kind.OBJECT_FIELD,
		name = name,
		value = self:parseValueLiteral(isConst),
		loc = self:loc(start),
	}
end

function Parser:parseDirectives(isConst)
	local directives = {}
	while self:peek(TokenKind.AT) do
		table.insert(directives, self:parseDirective(isConst))
	end
	return directives
end

--[[*
--  * Directive[Const] : @ Name Arguments[?Const]?
--  *]]
function Parser:parseDirective(isConst)
	local start = self._lexer.token
	self:expectToken(TokenKind.AT)
	return {
		kind = Kind.DIRECTIVE,
		name = self:parseName(),
		arguments = self:parseArguments(isConst),
		loc = self:loc(start),
	}
end

-- Implements the parsing rules in the Types section.

--[[*
--  * Type :
--  *   - NamedType
--  *   - ListType
--  *   - NonNullType
--  *]]
function Parser:parseTypeReference()
	local start = self._lexer.token
	local type_
	if self:expectOptionalToken(TokenKind.BRACKET_L) then
		type_ = self:parseTypeReference()
		self:expectToken(TokenKind.BRACKET_R)
		type_ = {
			kind = Kind.LIST_TYPE,
			type = type_,
			loc = self:loc(start),
		}
	else
		type_ = self:parseNamedType()
	end

	if self:expectOptionalToken(TokenKind.BANG) then
		return {
			kind = Kind.NON_NULL_TYPE,
			type = type_,
			loc = self:loc(start),
		}
	end
	return type_
end

--[[*
--  * NamedType : Name
--  *]]
function Parser:parseNamedType()
	local start = self._lexer.token
	return {
		kind = Kind.NAMED_TYPE,
		name = self:parseName(),
		loc = self:loc(start),
	}
end

--[[*
--  * TypeSystemDefinition :
--  *   - SchemaDefinition
--  *   - TypeDefinition
--  *   - DirectiveDefinition
--  *
--  * TypeDefinition :
--  *   - ScalarTypeDefinition
--  *   - ObjectTypeDefinition
--  *   - InterfaceTypeDefinition
--  *   - UnionTypeDefinition
--  *   - EnumTypeDefinition
--  *   - InputObjectTypeDefinition
--  *]]
function Parser:parseTypeSystemDefinition()
	-- Many definitions begin with a description and require a lookahead.
	local keywordToken = (function()
		if self:peekDescription() then
			return self._lexer:lookahead()
		else
			return self._lexer.token
		end
	end)()

	if keywordToken.kind == TokenKind.NAME then
		local tokenValue = keywordToken.value
		if tokenValue == "schema" then
			return self:parseSchemaDefinition()
		elseif tokenValue == "scalar" then
			return self:parseScalarTypeDefinition()
		elseif tokenValue == "type" then
			return self:parseObjectTypeDefinition()
		elseif tokenValue == "interface" then
			return self:parseInterfaceTypeDefinition()
		elseif tokenValue == "union" then
			return self:parseUnionTypeDefinition()
		elseif tokenValue == "enum" then
			return self:parseEnumTypeDefinition()
		elseif tokenValue == "input" then
			return self:parseInputObjectTypeDefinition()
		elseif tokenValue == "directive" then
			return self:parseDirectiveDefinition()
		end
	end

	error(self:unexpected(keywordToken))
end

function Parser:peekDescription()
	return self:peek(TokenKind.STRING) or self:peek(TokenKind.BLOCK_STRING)
end

--[[*
--  * Description : StringValue
--  *]]
function Parser:parseDescription()
	if self:peekDescription() then
		return self:parseStringLiteral()
	end
	return -- ROBLOX deviation: no implicit returns
end

--[[*
--  * SchemaDefinition : Description? schema Directives[Const]? { OperationTypeDefinition+ }
--  *]]
function Parser:parseSchemaDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("schema")
	local directives = self:parseDirectives(true)
	local operationTypes = self:many(TokenKind.BRACE_L, self.parseOperationTypeDefinition, TokenKind.BRACE_R)
	return {
		kind = Kind.SCHEMA_DEFINITION,
		description = description,
		directives = directives,
		operationTypes = operationTypes,
		loc = self:loc(start),
	}
end

--[[*
--  * OperationTypeDefinition : OperationType : NamedType
--  *]]
function Parser:parseOperationTypeDefinition()
	local start = self._lexer.token
	local operation = self:parseOperationType()
	self:expectToken(TokenKind.COLON)
	local type_ = self:parseNamedType()
	return {
		kind = Kind.OPERATION_TYPE_DEFINITION,
		operation = operation,
		type = type_,
		loc = self:loc(start),
	}
end

--[[*
--  * ScalarTypeDefinition : Description? scalar Name Directives[Const]?
--  *]]
function Parser:parseScalarTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("scalar")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	return {
		kind = Kind.SCALAR_TYPE_DEFINITION,
		description = description,
		name = name,
		directives = directives,
		loc = self:loc(start),
	}
end

--[[*
--  * ObjectTypeDefinition :
--  *   Description?
--  *   type Name ImplementsInterfaces? Directives[Const]? FieldsDefinition?
--  *]]
function Parser:parseObjectTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("type")
	local name = self:parseName()
	local interfaces = self:parseImplementsInterfaces()
	local directives = self:parseDirectives(true)
	local fields = self:parseFieldsDefinition()
	return {
		kind = Kind.OBJECT_TYPE_DEFINITION,
		description = description,
		name = name,
		interfaces = interfaces,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * ImplementsInterfaces :
--  *   - implements `&`? NamedType
--  *   - ImplementsInterfaces & NamedType
--  *]]
function Parser:parseImplementsInterfaces(): Array<any>
	if self:expectOptionalKeyword("implements") then
		return self:delimitedMany(TokenKind.AMP, self.parseNamedType)
	else
		return {}
	end
end

--[[*
--  * FieldsDefinition : { FieldDefinition+ }
--  *]]
function Parser:parseFieldsDefinition()
	return self:optionalMany(TokenKind.BRACE_L, self.parseFieldDefinition, TokenKind.BRACE_R)
end

--[[*
--  * FieldDefinition :
--  *   - Description? Name ArgumentsDefinition? : Type Directives[Const]?
--  *]]
function Parser:parseFieldDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	local name = self:parseName()
	local args = self:parseArgumentDefs()
	self:expectToken(TokenKind.COLON)
	local type_ = self:parseTypeReference()
	local directives = self:parseDirectives(true)
	return {
		kind = Kind.FIELD_DEFINITION,
		description = description,
		name = name,
		arguments = args,
		type = type_,
		directives = directives,
		loc = self:loc(start),
	}
end

--[[*
--  * ArgumentsDefinition : ( InputValueDefinition+ )
--  *]]
function Parser:parseArgumentDefs()
	return self:optionalMany(TokenKind.PAREN_L, self.parseInputValueDef, TokenKind.PAREN_R)
end

--[[*
--  * InputValueDefinition :
--  *   - Description? Name : Type DefaultValue? Directives[Const]?
--  *]]
function Parser:parseInputValueDef()
	local start = self._lexer.token
	local description = self:parseDescription()
	local name = self:parseName()
	self:expectToken(TokenKind.COLON)
	local type_ = self:parseTypeReference()
	local defaultValue
	if self:expectOptionalToken(TokenKind.EQUALS) then
		defaultValue = self:parseValueLiteral(true)
	end
	local directives = self:parseDirectives(true)
	return {
		kind = Kind.INPUT_VALUE_DEFINITION,
		description = description,
		name = name,
		type = type_,
		defaultValue = defaultValue,
		directives = directives,
		loc = self:loc(start),
	}
end

--[[*
--  * InterfaceTypeDefinition :
--  *   - Description? interface Name Directives[Const]? FieldsDefinition?
--  *]]
function Parser:parseInterfaceTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("interface")
	local name = self:parseName()
	local interfaces = self:parseImplementsInterfaces()
	local directives = self:parseDirectives(true)
	local fields = self:parseFieldsDefinition()
	return {
		kind = Kind.INTERFACE_TYPE_DEFINITION,
		description = description,
		name = name,
		interfaces = interfaces,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * UnionTypeDefinition :
--  *   - Description? union Name Directives[Const]? UnionMemberTypes?
--  *]]
function Parser:parseUnionTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("union")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local types = self:parseUnionMemberTypes()
	return {
		kind = Kind.UNION_TYPE_DEFINITION,
		description = description,
		name = name,
		directives = directives,
		types = types,
		loc = self:loc(start),
	}
end

--[[*
--  * UnionMemberTypes :
--  *   - = `|`? NamedType
--  *   - UnionMemberTypes | NamedType
--  *]]
function Parser:parseUnionMemberTypes()
	local types = {}
	if self:expectOptionalToken(TokenKind.EQUALS) then
		--   // Optional leading pipe
		self:expectOptionalToken(TokenKind.PIPE)
		repeat
			table.insert(types, self:parseNamedType())
		until not self:expectOptionalToken(TokenKind.PIPE)
	end
	return types
end

--[[*
--  * EnumTypeDefinition :
--  *   - Description? enum Name Directives[Const]? EnumValuesDefinition?
--  *]]
function Parser:parseEnumTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("enum")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local values = self:parseEnumValuesDefinition()
	return {
		kind = Kind.ENUM_TYPE_DEFINITION,
		description = description,
		name = name,
		directives = directives,
		values = values,
		loc = self:loc(start),
	}
end

--[[*
--  * EnumValuesDefinition : { EnumValueDefinition+ }
--  *]]
function Parser:parseEnumValuesDefinition()
	return self:optionalMany(TokenKind.BRACE_L, self.parseEnumValueDefinition, TokenKind.BRACE_R)
end

--[[*
--  * EnumValueDefinition : Description? EnumValue Directives[Const]?
--  *
--  * EnumValue : Name
--  *]]
function Parser:parseEnumValueDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	return {
		kind = Kind.ENUM_VALUE_DEFINITION,
		description = description,
		name = name,
		directives = directives,
		loc = self:loc(start),
	}
end

--[[*
--  * InputObjectTypeDefinition :
--  *   - Description? input Name Directives[Const]? InputFieldsDefinition?
--  *]]
function Parser:parseInputObjectTypeDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("input")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local fields = self:parseInputFieldsDefinition()
	return {
		kind = Kind.INPUT_OBJECT_TYPE_DEFINITION,
		description = description,
		name = name,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * InputFieldsDefinition : { InputValueDefinition+ }
--  *]]
function Parser:parseInputFieldsDefinition()
	return self:optionalMany(TokenKind.BRACE_L, self.parseInputValueDef, TokenKind.BRACE_R)
end

--[[*
--  * TypeSystemExtension :
--  *   - SchemaExtension
--  *   - TypeExtension
--  *
--  * TypeExtension :
--  *   - ScalarTypeExtension
--  *   - ObjectTypeExtension
--  *   - InterfaceTypeExtension
--  *   - UnionTypeExtension
--  *   - EnumTypeExtension
--  *   - InputObjectTypeDefinition
--  *]]
function Parser:parseTypeSystemExtension()
	local keywordToken = self._lexer:lookahead()

	if keywordToken.kind == TokenKind.NAME then
		local tokenValue = keywordToken.value
		if tokenValue == "schema" then
			return self:parseSchemaExtension()
		elseif tokenValue == "scalar" then
			return self:parseScalarTypeExtension()
		elseif tokenValue == "type" then
			return self:parseObjectTypeExtension()
		elseif tokenValue == "interface" then
			return self:parseInterfaceTypeExtension()
		elseif tokenValue == "union" then
			return self:parseUnionTypeExtension()
		elseif tokenValue == "enum" then
			return self:parseEnumTypeExtension()
		elseif tokenValue == "input" then
			return self:parseInputObjectTypeExtension()
		end
	end

	error(self:unexpected(keywordToken))
end

--[[*
--  * SchemaExtension :
--  *  - extend schema Directives[Const]? { OperationTypeDefinition+ }
--  *  - extend schema Directives[Const]
--  *]]
function Parser:parseSchemaExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("schema")
	local directives = self:parseDirectives(true)
	local operationTypes = self:optionalMany(TokenKind.BRACE_L, self.parseOperationTypeDefinition, TokenKind.BRACE_R)
	if #directives == 0 and #operationTypes == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.SCHEMA_EXTENSION,
		directives = directives,
		operationTypes = operationTypes,
		loc = self:loc(start),
	}
end

--[[*
--  * ScalarTypeExtension :
--  *   - extend scalar Name Directives[Const]
--  *]]
function Parser:parseScalarTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("scalar")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	if #directives == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.SCALAR_TYPE_EXTENSION,
		name = name,
		directives = directives,
		loc = self:loc(start),
	}
end

--[[*
--  * ObjectTypeExtension :
--  *  - extend type Name ImplementsInterfaces? Directives[Const]? FieldsDefinition
--  *  - extend type Name ImplementsInterfaces? Directives[Const]
--  *  - extend type Name ImplementsInterfaces
--  *]]
function Parser:parseObjectTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("type")
	local name = self:parseName()
	local interfaces = self:parseImplementsInterfaces()
	local directives = self:parseDirectives(true)
	local fields = self:parseFieldsDefinition()
	if #interfaces == 0 and #directives == 0 and #fields == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.OBJECT_TYPE_EXTENSION,
		name = name,
		interfaces = interfaces,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * InterfaceTypeExtension :
--  *  - extend interface Name ImplementsInterfaces? Directives[Const]? FieldsDefinition
--  *  - extend interface Name ImplementsInterfaces? Directives[Const]
--  *  - extend interface Name ImplementsInterfaces
--  *]]
function Parser:parseInterfaceTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("interface")
	local name = self:parseName()
	local interfaces = self:parseImplementsInterfaces()
	local directives = self:parseDirectives(true)
	local fields = self:parseFieldsDefinition()
	if #interfaces == 0 and #directives == 0 and #fields == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.INTERFACE_TYPE_EXTENSION,
		name = name,
		interfaces = interfaces,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * UnionTypeExtension :
--  *   - extend union Name Directives[Const]? UnionMemberTypes
--  *   - extend union Name Directives[Const]
--  *]]
function Parser:parseUnionTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("union")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local types = self:parseUnionMemberTypes()
	if #directives == 0 and #types == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.UNION_TYPE_EXTENSION,
		name = name,
		directives = directives,
		types = types,
		loc = self:loc(start),
	}
end

--[[*
--  * EnumTypeExtension :
--  *   - extend enum Name Directives[Const]? EnumValuesDefinition
--  *   - extend enum Name Directives[Const]
--  *]]
function Parser:parseEnumTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("enum")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local values = self:parseEnumValuesDefinition()
	if #directives == 0 and #values == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.ENUM_TYPE_EXTENSION,
		name = name,
		directives = directives,
		values = values,
		loc = self:loc(start),
	}
end

--[[*
--  * InputObjectTypeExtension :
--  *   - extend input Name Directives[Const]? InputFieldsDefinition
--  *   - extend input Name Directives[Const]
--  *]]
function Parser:parseInputObjectTypeExtension()
	local start = self._lexer.token
	self:expectKeyword("extend")
	self:expectKeyword("input")
	local name = self:parseName()
	local directives = self:parseDirectives(true)
	local fields = self:parseInputFieldsDefinition()
	if #directives == 0 and #fields == 0 then
		error(self:unexpected())
	end
	return {
		kind = Kind.INPUT_OBJECT_TYPE_EXTENSION,
		name = name,
		directives = directives,
		fields = fields,
		loc = self:loc(start),
	}
end

--[[*
--  * DirectiveDefinition :
--  *   - Description? directive @ Name ArgumentsDefinition? `repeatable`? on DirectiveLocations
--  *]]
function Parser:parseDirectiveDefinition()
	local start = self._lexer.token
	local description = self:parseDescription()
	self:expectKeyword("directive")
	self:expectToken(TokenKind.AT)
	local name = self:parseName()
	local args = self:parseArgumentDefs()
	local repeatable = self:expectOptionalKeyword("repeatable")
	self:expectKeyword("on")
	local locations = self:parseDirectiveLocations()
	return {
		kind = Kind.DIRECTIVE_DEFINITION,
		description = description,
		name = name,
		arguments = args,
		repeatable = repeatable,
		locations = locations,
		loc = self:loc(start),
	}
end

--[[*
--  * DirectiveLocations :
--  *   - `|`? DirectiveLocation
--  *   - DirectiveLocations | DirectiveLocation
--  *]]
function Parser:parseDirectiveLocations()
	-- Optional leading pipe
	self:expectOptionalToken(TokenKind.PIPE)
	local locations = {}
	repeat
		table.insert(locations, self:parseDirectiveLocation())
	until not self:expectOptionalToken(TokenKind.PIPE)
	return locations
end

--[[*
--  * DirectiveLocation :
--  *   - ExecutableDirectiveLocation
--  *   - TypeSystemDirectiveLocation
--  *
--  * ExecutableDirectiveLocation : one of
--  *   `QUERY`
--  *   `MUTATION`
--  *   `SUBSCRIPTION`
--  *   `FIELD`
--  *   `FRAGMENT_DEFINITION`
--  *   `FRAGMENT_SPREAD`
--  *   `INLINE_FRAGMENT`
--  *
--  * TypeSystemDirectiveLocation : one of
--  *   `SCHEMA`
--  *   `SCALAR`
--  *   `OBJECT`
--  *   `FIELD_DEFINITION`
--  *   `ARGUMENT_DEFINITION`
--  *   `INTERFACE`
--  *   `UNION`
--  *   `ENUM`
--  *   `ENUM_VALUE`
--  *   `INPUT_OBJECT`
--  *   `INPUT_FIELD_DEFINITION`
--  *]]
function Parser:parseDirectiveLocation()
	local start = self._lexer.token
	local name = self:parseName()
	if DirectiveLocation[name.value] ~= nil then
		return name
	end
	error(self:unexpected(start))
end

--[[*
--  * Returns a location object, used to identify the place in
--  * the source that created a given parsed object.
--  *]]
function Parser:loc(startToken)
	if (self._options and self._options.noLocation) ~= true then
		return Location.new(startToken, self._lexer.lastToken, self._lexer.source)
	end
	return
end

--[[*
--  * Determines if the next token is of a given kind
--  *]]
function Parser:peek(kind)
	return self._lexer.token.kind == kind
end

--[[*
--  * If the next token is of the given kind, return that token after advancing
--  * the lexer. Otherwise, do not change the parser state and throw an error.
--  *]]
function Parser:expectToken(kind)
	local token = self._lexer.token
	if token.kind == kind then
		self._lexer:advance()
		return token
	end

	error(syntaxError(
		self._lexer.source,
		token.start,
		"Expected " .. getTokenKindDesc(kind) .. ", found " .. getTokenDesc(token) .. "."
	))
end

--[[*
--  * If the next token is of the given kind, return that token after advancing
--  * the lexer. Otherwise, do not change the parser state and return undefined.
--  *]]
function Parser:expectOptionalToken(kind)
	local token = self._lexer.token
	if token.kind == kind then
		self._lexer:advance()
		return token
	end
	return nil
end

--[[*
--  * If the next token is a given keyword, advance the lexer.
--  * Otherwise, do not change the parser state and throw an error.
--  *]]
function Parser:expectKeyword(value)
	local token = self._lexer.token
	if token.kind == TokenKind.NAME and token.value == value then
		self._lexer:advance()
	else
		error(syntaxError(
			self._lexer.source,
			token.start,
			"Expected \"" .. value .. "\", found " .. getTokenDesc(token) .. "."
		))
	end
end

--[[*
--  * If the next token is a given keyword, return "true" after advancing
--  * the lexer. Otherwise, do not change the parser state and return "false".
--  *]]
function Parser:expectOptionalKeyword(value: string): boolean
	local token = self._lexer.token
	if token.kind == TokenKind.NAME and token.value == value then
		self._lexer:advance()
		return true
	end
	return false
end

--[[*
--  * Helper function for creating an error when an unexpected lexed token
--  * is encountered.
--  *]]
function Parser:unexpected(atToken)
	local token = atToken ~= nil and atToken or self._lexer.token
	return syntaxError(
		self._lexer.source,
		token.start,
		"Unexpected " .. getTokenDesc(token) .. "."
	)
end

--[[*
--  * Returns a possibly empty list of parse nodes, determined by
--  * the parseFn. This list begins with a lex token of openKind
--  * and ends with a lex token of closeKind. Advances the parser
--  * to the next lex token after the closing token.
--  *]]
function Parser:any(openKind, parseFn, closeKind)
	self:expectToken(openKind)
	local nodes = {}
	while not self:expectOptionalToken(closeKind) do
		table.insert(nodes, parseFn(self))
	end
	return nodes
end

--[[*
--  * Returns a list of parse nodes, determined by the parseFn.
--  * It can be empty only if open token is missing otherwise it will always
--  * return non-empty list that begins with a lex token of openKind and ends
--  * with a lex token of closeKind. Advances the parser to the next lex token
--  * after the closing token.
--  *]]
function Parser:optionalMany(openKind, parseFn, closeKind)
	if self:expectOptionalToken(openKind) then
		local nodes = {}
		repeat
			table.insert(nodes, parseFn(self))
		until self:expectOptionalToken(closeKind)
		return nodes
	end
	return {}
end

--[[*
--  * Returns a non-empty list of parse nodes, determined by
--  * the parseFn. This list begins with a lex token of openKind
--  * and ends with a lex token of closeKind. Advances the parser
--  * to the next lex token after the closing token.
--  *]]
function Parser:many(openKind, parseFn, closeKind)
	self:expectToken(openKind)
	local nodes = {}
	repeat
		table.insert(nodes, parseFn(self))
	until self:expectOptionalToken(closeKind)
	return nodes
end

--[[*
* Returns a non-empty list of parse nodes, determined by the parseFn.
* This list may begin with a lex token of delimiterKind followed by items separated by lex tokens of tokenKind.
* Advances the parser to the next lex token after last item in the list.
]]
function Parser:delimitedMany(delimiterKind, parseFn: (any) -> any): Array<any>
 self:expectOptionalToken(delimiterKind);

 local nodes = {}
 repeat
	table.insert(nodes, parseFn(self))
 until not (self:expectOptionalToken(delimiterKind))
 return nodes
end

--[[*
--  * A helper function to describe a token as a string for debugging
--  *]]
function getTokenDesc(token): string
	local value = token.value
	return getTokenKindDesc(token.kind) .. (value ~= nil and " \"" .. value .. "\"" or "")
end

--[[*
--  * A helper function to describe a token kind as a string for debugging
--  *]]
function getTokenKindDesc(kind): string
	return isPunctuatorTokenKind(kind) and "\"" .. kind .. "\"" or kind
end

return {
	Parser = Parser,
	parse = parse,
	parseValue = parseValue,
	parseType = parseType,
}
