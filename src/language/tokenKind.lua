-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/tokenKind.js

local exports = {}

exports.TokenKind = {
	SOF = "<SOF>",
	EOF = "<EOF>",
	BANG = "!",
	DOLLAR = "$",
	AMP = "&",
	PAREN_L = "(",
	PAREN_R = ")",
	SPREAD = "...",
	COLON = ":",
	EQUALS = "=",
	AT = "@",
	BRACKET_L = "[",
	BRACKET_R = "]",
	BRACE_L = "{",
	PIPE = "|",
	BRACE_R = "}",
	NAME = "Name",
	INT = "Int",
	FLOAT = "Float",
	STRING = "String",
	BLOCK_STRING = "BlockString",
	COMMENT = "Comment",
}

return exports
