-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/tokenKind.js
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

--[[*
 * The enum type representing the token kinds values.
 ]]
-- ROBLOX deivation: Luau types can't express this, so we reduce it to string
-- export type TokenKindEnum = $Values<typeof TokenKind>;
export type TokenKindEnum = string

return exports
