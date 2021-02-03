-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/stripIgnoredCharacters.js

local srcWorkspace = script.Parent.Parent
local languageWorkspace = srcWorkspace.language

local sourceImport = require(languageWorkspace.source)
local Source = sourceImport.Source
local isSource = sourceImport.isSource
local TokenKind = require(languageWorkspace.tokenKind).TokenKind
local lexerImport = require(languageWorkspace.lexer)
local Lexer = lexerImport.Lexer
local isPunctuatorTokenKind = lexerImport.isPunctuatorTokenKind
local blockStringImport = require(languageWorkspace.blockString)
local dedentBlockStringValue = blockStringImport.dedentBlockStringValue
local getBlockStringIndentation = blockStringImport.getBlockStringIndentation

local String = require(srcWorkspace.luaUtils.String)

-- ROBLOX deviation: pre-declare functions
local dedentBlockString

--[[*
--  * Strips characters that are not significant to the validity or execution
--  * of a GraphQL document:
--  *   - UnicodeBOM
--  *   - WhiteSpace
--  *   - LineTerminator
--  *   - Comment
--  *   - Comma
--  *   - BlockString indentation
--  *
--  * Note: It is required to have a delimiter character between neighboring
--  * non-punctuator tokens and this function always uses single space as delimiter.
--  *
--  * It is guaranteed that both input and output documents if parsed would result
--  * in the exact same AST except for nodes location.
--  *
--  * Warning: It is guaranteed that this function will always produce stable results.
--  * However, it's not guaranteed that it will stay the same between different
--  * releases due to bugfixes or changes in the GraphQL specification.
--  *
--  * Query example:
--  *
--  * query SomeQuery($foo: String!, $bar: String) {
--  *   someField(foo: $foo, bar: $bar) {
--  *     a
--  *     b {
--  *       c
--  *       d
--  *     }
--  *   }
--  * }
--  *
--  * Becomes:
--  *
--  * query SomeQuery($foo:String!$bar:String){someField(foo:$foo bar:$bar){a b{c d}}}
--  *
--  * SDL example:
--  *
--  * """
--  * Type description
--  * """
--  * type Foo {
--  *   """
--  *   Field description
--  *   """
--  *   bar: String
--  * }
--  *
--  * Becomes:
--  *
--  * """Type description""" type Foo{"""Field description""" bar:String}
--  *]]
local function stripIgnoredCharacters(source: string | any): string
	local sourceObj
	if isSource(source) then
		sourceObj = source
	else
		sourceObj = Source.new(source)
	end

	local body = sourceObj.body
	local lexer = Lexer.new(sourceObj)
	local strippedBody = ""

	local wasLastAddedTokenNonPunctuator = false
	while lexer:advance().kind ~= TokenKind.EOF do
		local currentToken = lexer.token
		local tokenKind = currentToken.kind

		--[[*
		--  * Every two non-punctuator tokens should have space between them.
		--  * Also prevent case of non-punctuator token following by spread resulting
		--  * in invalid token (e.g. `1...` is invalid Float token).
		--  *]]
		local isNonPunctuator = not isPunctuatorTokenKind(currentToken.kind)
		if wasLastAddedTokenNonPunctuator then
			if isNonPunctuator or currentToken.kind == TokenKind.SPREAD then
				strippedBody ..= " "
			end
		end

        local tokenBody = String.slice(body, currentToken.start, currentToken._end)
		if tokenKind == TokenKind.BLOCK_STRING then
			strippedBody ..= dedentBlockString(tokenBody)
		else
			strippedBody ..= tokenBody
		end

		wasLastAddedTokenNonPunctuator = isNonPunctuator
	end

	return strippedBody
end

function dedentBlockString(blockStr: string): string
	-- skip leading and trailing triple quotations
	local rawStr = String.slice(blockStr, 4, -3)
	local body = dedentBlockStringValue(rawStr)

	if getBlockStringIndentation(body) > 0 then
		body = "\n" .. body
	end

	local lastChar = String.slice(body, utf8.len(body))
	local hasTrailingQuote = lastChar == "\"" and String.slice(body, -4) ~= "\\\"\"\""
	if hasTrailingQuote or lastChar == "\\" then
		body ..= "\n"
	end

	return "\"\"\"" .. body .. "\"\"\""
end

return {
	stripIgnoredCharacters = stripIgnoredCharacters,
}
