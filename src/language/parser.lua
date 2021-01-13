-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/parser.js

local language = script.Parent
local jsUtils = language.Parent.jsutils

local inspect = require(jsUtils.inspect)
local devAssert = require(jsUtils.devAssert)
local instanceOf = require(jsUtils.instanceOf)

local Location = require(language.ast).Location

local sourceModule = require(language.source)
local Source = sourceModule.Source

local lexer = require(language.lexer)
local Lexer = lexer.Lexer
local isPunctuatorTokenKind = lexer.isPunctuatorTokenKind

local TokenKind = require(language.tokenKind).TokenKind
local Kind = require(language.kinds).Kind

local syntaxError = require(script.Parent.Parent.error.syntaxError)

-- deviation: pre-declare functions
local getTokenDesc
local getTokenKindDesc

local Parser = {}
Parser.__index = Parser

-- /**
--  * Given a GraphQL source, parses it into a Document.
--  * Throws GraphQLError if a syntax error is encountered.
--  */
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

-- /**
--  * Given a string containing a GraphQL Type (ex. `[Int!]`), parse the AST for
--  * that type.
--  * Throws GraphQLError if a syntax error is encountered.
--  *
--  * This is useful within tools that operate upon GraphQL Types directly and
--  * in isolation of complete GraphQL documents.
--  *
--  * Consider providing the results to the utility function: typeFromAST().
--  */
local function parseType(source, options)
	local parser = Parser.new(source, options)
	parser:expectToken(TokenKind.SOF)
	local type = parser:parseTypeReference()
	parser:expectToken(TokenKind.EOF)
	return type
end

function Parser.new(source, options)
	local sourceObj = type(source) == "string" and Source.new(source) or source
	devAssert(
		instanceOf(sourceObj, Source),
		"Must provide Source. Received: " .. inspect(sourceObj) .. "."
	)
	local self = {}
	self._lexer = Lexer.new(sourceObj)
	self._options = options

	return setmetatable(self, Parser)
end

function Parser:parseName()
	local token = self:expectToken(TokenKind.NAME)
	return {
		kind = Kind.NAME,
		value = token.value,
		loc = self:loc(token),
	}
end

function Parser:parseDocument()
	local start = self._lexer.token
	return {
		kind = Kind.DOCUMENT,
		definitions = self:many(TokenKind.SOF, self.parseDefinition, TokenKind.EOF),
		loc = self:loc(start),
	}
end

function Parser:parseDefinition()
	if self:peek(TokenKind.NAME) then
		local tokenValue = self._lexer.token.value
		if tokenValue == "query" or tokenValue == "mutation" or tokenValue == "subscription" then
			return self:parseOperationDefinition()
		elseif tokenValue == "fragment" then
			return self:parseFragmentDefinition()
		elseif tokenValue == "schema" or
			   tokenValue == "scalar" or
			   tokenValue == "type" or
			   tokenValue == "interface" or
			   tokenValue == "union" or
			   tokenValue == "enum" or
			   tokenValue == "input" or
			   tokenValue == "directive" then
			return self:parseTypeSystemDefinition()
		elseif tokenValue == "extend" then
			return self:parseTypeSystemExtension()
		end
	elseif self:peek(TokenKind.BRACE_L) then
		return self:parseOperationDefinition()
	elseif self:peekDescription() then
		return self:parseTypeSystemDefinition()
	end

	return self:unexpected()
end

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

function Parser:parseOperationType()
	local operationToken = self:expectToken(TokenKind.NAME)

	if operationToken.value == "query" then
		return "query"
	elseif operationToken.value == "mution" then
		return "mutation"
	elseif operationToken.value == "subscription" then
		return "subscription"
	end

	error(self:unexpected(operationToken))
end

function Parser:parseVariableDefinitions()
	return self:optionalMany(TokenKind.PAREN_L, self.parseVariableDefinition, TokenKind.PAREN_R)
end

function Parser:parseVariableDefinition()
	error("Parser.parseVariableDefinition unimplemented")
end

function Parser:parseVariable()
	error("Parser.parseVariable unimplemented")
end

function Parser:parseSelectionSet()
	local start = self._lexer.token
	return {
		kind = Kind.SELECTION_SET,
		selections = self:many(TokenKind.BRACE_L, self.parseSelection, TokenKind.BRACE_R),
		loc = self:loc(start),
	}
end

function Parser:parseSelection()
	return self:peek(TokenKind.SPREAD) and self:parseFragment() or self:parseField()
end

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

function Parser:parseArguments(isConst)
	error("Parser.parseArguments unimplemented")
end

function Parser:parseArgument()
	error("Parser.parseArgument unimplemented")
end

function Parser:parseConstArgument()
	error("Parser.parseConstArgument unimplemented")
end

function Parser:parseFragment()
	error("Parser.parseFragment unimplemented")
end

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

function Parser:parseFragmentName()
	if self._lexer.token.value == "on" then
		error(self:unexpected())
	end
	return self:parseName()
end

function Parser:parseValueLiteral()
	error("Parser.parseValueLiteral unimplemented")
end

function Parser:parseStringLiteral()
	error("Parser.parseStringLiteral unimplemented")
end

function Parser:parseList()
	error("Parser.parseList unimplemented")
end

function Parser:parseObject()
	error("Parser.parseObject unimplemented")
end

function Parser:parseObjectField()
	error("Parser.parseObjectField unimplemented")
end

function Parser:parseDirectives(isConst)
	error("Parser.parseDirectives unimplemented")
end

function Parser:parseDirective()
	error("Parser.parseDirective unimplemented")
end

function Parser:parseTypeReference()
	error("Parser.parseTypeReference unimplemented")
end

function Parser:parseNamedType()
	error("Parser.parseNamedType unimplemented")
end

function Parser:parseTypeSystemDefinition()
	error("Parser.parseTypeSystemDefinition unimplemented")
end

function Parser:peekDescription()
	error("Parser.peekDescription unimplemented")
end

function Parser:parseDescription()
	error("Parser.parseDescription unimplemented")
end

function Parser:parseSchemaDefinition()
	error("Parser.parseSchemaDefinition unimplemented")
end

function Parser:parseOperationTypeDefinition()
	error("Parser.parseOperationTypeDefinition unimplemented")
end

function Parser:parseScalarTypeDefinition()
	error("Parser.parseScalarTypeDefinition unimplemented")
end

function Parser:parseObjectTypeDefinition()
	error("Parser.parseObjectTypeDefinition unimplemented")
end

function Parser:parseImplementsInterfaces()
	error("Parser.parseImplementsInterfaces unimplemented")
end

function Parser:parseFieldsDefinition()
	error("Parser.parseFieldsDefinition unimplemented")
end

function Parser:parseFieldDefinition()
	error("Parser.parseFieldDefinition unimplemented")
end

function Parser:parseArgumentDefs()
	error("Parser.parseArgumentDefs unimplemented")
end

function Parser:parseInputValueDef()
	error("Parser.parseInputValueDef unimplemented")
end

function Parser:parseInterfaceTypeDefinition()
	error("Parser.parseInterfaceTypeDefinition unimplemented")
end

function Parser:parseUnionTypeDefinition()
	error("Parser.parseUnionTypeDefinition unimplemented")
end

function Parser:parseUnionMemberTypes()
	error("Parser.parseUnionMemberTypes unimplemented")
end

function Parser:parseEnumTypeDefinition()
	error("Parser.parseEnumTypeDefinition unimplemented")
end

function Parser:parseEnumValuesDefinition()
	error("Parser.parseEnumValuesDefinition unimplemented")
end

function Parser:parseEnumValueDefinition()
	error("Parser.parseEnumValueDefinition unimplemented")
end

function Parser:parseInputObjectTypeDefinition()
	error("Parser.parseInputObjectTypeDefinition unimplemented")
end

function Parser:parseInputFieldsDefinition()
	error("Parser.parseInputFieldsDefinition unimplemented")
end

function Parser:parseTypeSystemExtension()
	error("Parser.parseTypeSystemExtension unimplemented")
end

function Parser:parseSchemaExtension()
	error("Parser.parseSchemaExtension unimplemented")
end

function Parser:parseScalarTypeExtension()
	error("Parser.parseScalarTypeExtension unimplemented")
end

function Parser:parseObjectTypeExtension()
	error("Parser.parseObjectTypeExtension unimplemented")
end

function Parser:parseInterfaceTypeExtension()
	error("Parser.parseInterfaceTypeExtension unimplemented")
end

function Parser:parseUnionTypeExtension()
	error("Parser.parseUnionTypeExtension unimplemented")
end

function Parser:parseEnumTypeExtension()
	error("Parser.parseEnumTypeExtension unimplemented")
end

function Parser:parseInputObjectTypeExtension()
	error("Parser.parseInputObjectTypeExtension unimplemented")
end

function Parser:parseDirectiveDefinition()
	error("Parser.parseDirectiveDefinition unimplemented")
end

function Parser:parseDirectiveLocations()
	error("Parser.parseDirectiveLocations unimplemented")
end

function Parser:parseDirectiveLocation()
	error("Parser.parseDirectiveLocation unimplemented")
end

function Parser:loc(startToken)
	if (self._options and self._options.noLocation) ~= true then
		return Location.new(startToken, self._lexer.lastToken, self._lexer.source)
	end
	return
end

function Parser:peek(kind)
	return self._lexer.token.kind == kind
end

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

function Parser:expectOptionalToken(kind)
	local token = self._lexer.token
	if token.kind == kind then
		self._lexer:advance()
		return token
	end
	return nil
end

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

function Parser:expectOptionalKeyword()
	error("Parser.expectOptionalKeyword unimplemented")
end

function Parser:unexpected(atToken)
	local token = atToken ~= nil and atToken or self._lexer.token
	return syntaxError(
		self._lexer.source,
		token.start,
		"Unexpected " .. getTokenDesc(token) .. "."
	)
end

function Parser:any()
	error("Parser.any unimplemented")
end

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

function Parser:many(openKind, parseFn, closeKind)
	self:expectToken(openKind)
	local nodes = {}
	repeat
		table.insert(nodes, parseFn(self))
	until self:expectOptionalToken(closeKind)
	return nodes
end

function Parser:delimitedMany(delimiterKind, parseFn)
	self:expectOptionalToken(delimiterKind)
	local nodes = {}
	repeat
		table.insert(nodes, parseFn())
	until not self:expectOptionalToken(delimiterKind)
	return nodes
end

function getTokenDesc(token: Token): string
	local value = token.value
	return getTokenKindDesc(token.kind) .. (value ~= nil and " \"" .. value .. "\"" or "")
end

function getTokenKindDesc(kind: TokenKindEnum): string
	return isPunctuatorTokenKind(kind) and "\"" .. kind .. "\"" or kind
end

------
-- TODO
------

local exports = {
	Parser = Parser,
	parse = parse,
	parseValue = parseValue,
	parseType = parseType,
}

return exports
