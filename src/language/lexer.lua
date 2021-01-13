-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/lexer.js


local language = script.Parent
local src = language.Parent
local Packages = src.Parent.Packages

local json = require(src.luaUtils.json)
local Number = require(Packages.LuauPolyfill).Number
local isNaN = Number.isNaN


local syntaxError = require(src.error.syntaxError)
local TokenKind = require(language.tokenKind).TokenKind
local Token = require(language.ast).Token
local slice = require(src.luaUtils.slice).sliceString
local toUnicodeString = require(src.luaUtils.toUnicodeString)

-- deviation: pre-declare functions
local readBlockString
local readString

local charCodeAt = require(src.luaUtils.charCodeAt)
--[[
 Reads an alphanumeric + underscore name from the source.

 [_A-Za-z][_0-9A-Za-z]*
]]--
local function readName(
  source,
  start,
  line,
  col,
  prev
)
	local body = source.body
	local bodyLength = string.len(body)
	local position = start + 1
	local code: number = 0

	local firstCondition = function()
		return position ~= bodyLength + 1
	end
	-- local secondCondition = false
	local secondCondition = function ()
		code = charCodeAt(body, position, position)
		return not isNaN(code)
	end
	local thirdConditionFirstPart = function()
		return code == 95
	end -- _
	local thirdConditionSecondPart = function()
		return code >= 48 and code <= 57
	end -- 0 - 9
	local thirdConditionThirdPart = function()
		return code >= 65 and code <= 90
	end -- A - Z
	local thirdConditionFourthPart = function()
		return code >= 97 and code <= 122
	end -- a - z
	local thirdCondition = function()
		return thirdConditionFirstPart()
			or thirdConditionSecondPart()
			or thirdConditionThirdPart()
			or thirdConditionFourthPart()
	end

	while firstCondition() and
	   	secondCondition() and
		thirdCondition()
	do
		position += 1
	end

  	return Token.new(
					TokenKind.NAME,
					start,
					position,
					line,
					col,
					prev,
					slice(body, start, position)
	)
end

--[[
 -- Reads a comment token from the source file.
 --
 -- #[\u0009\u0020-\uFFFF]*
]]--
local function readComment(
  source,
  start,
  line,
  col,
  prev
)
  local body = source.body;
  local code;
	local position = start;

	position = position + 1
	code = charCodeAt(body, position + 1)

	-- // SourceCharacter but not LineTerminator
	local firstCondition = code > 0x001f or code == 0x0009

	while firstCondition
	-- and !isNaN(code) and
	do
		position = position + 1
		code = charCodeAt(body, position + 1)
	end

  return Token.new(
    TokenKind.COMMENT,
    start,
    position,
    line,
    col,
    prev,
    slice(body, start + 1, position)
  )
end

function printCharCode(code)
    -- NaN/undefined represents access beyond the end of the file.
	if isNaN(code) then
		return TokenKind.EOF
	else
	-- Trust JSON for ASCII.
	if code < 0x007f then
		return json.stringify(string.char(code))
	else
	-- Otherwise print the escaped form.
	return "\\u00" .. slice(
		string.upper(
			toUnicodeString(tostring(code))
		),
		-4
	)
	  end
	end
end

--[[
 Returns the new position in the source after reading digits.
]]--
function readDigits(source, start, firstCode)
  local body = source.body;
  local position = start;
	local code = firstCode;

  if code >= 48 and code <= 57 then
		-- 0 - 9
		while true do
			position += 1
			code = charCodeAt(body, position + 1);

			if not (code >= 48 and code <= 57) then -- 0 - 9
				break
			end
		end

		return position
  end
  error(syntaxError(
    source,
    position,
    "Invalid number, expected digit but got: " .. printCharCode(code) .. "."
  ))
end

--[[
 Report a message that an unexpected character was encountered.
]]--
function unexpectedCharacterMessage(code)
  if code < 0x0020 and code ~= 0x0009 and code ~= 0x000a and code ~= 0x000d then
    return "Cannot contain the invalid character  " .. printCharCode(code) .. "."
	end

  if code == 39 then
    -- '
    return 'Unexpected single quote character (\'), did you mean to use a double quote (")?';
	end

  return "Cannot parse the unexpected character " .. printCharCode(code) .. ".";
end

-- _ A-Z a-z
function isNameStart(code)
	local firstCondition = code == 95
	local secondCondition = code >= 65 and code <= 90
	local thirdCondition = code >= 97 and code <= 122
  return (
    firstCondition or secondCondition or thirdCondition
  );
end

--[[
 * Reads a number token from the source file, either a float
 * or an int depending on whether a decimal point appears.
 *
 * Int:   -?(0|[1-9][0-9]*)
 * Float: -?(0|[1-9][0-9]*)(\.[0-9]+)?((E|e)(+|-)?[0-9]+)?
]]--
function readNumber(
  source,
  start,
  firstCode,
  line,
  col,
  prev
)
  local body = source.body;
  local code = firstCode;
  local position = start;
  local isFloat = false;

  if code == 45 then
	-- -
		position += 1
    	code = charCodeAt(body, position + 1);
	end

  if code == 48 then
		-- 0
		position += 1
    	code = charCodeAt(body, position + 1);
    if code >= 48 and code <= 57 then
      error(syntaxError(
        source,
        position,
        "Invalid number, unexpected digit after 0: " .. printCharCode(code) .. "."
      ))
    end
  else
    position = readDigits(source, position, code);
    code = charCodeAt(body, position + 1);
  end

  if code == 46 then
    -- .
    isFloat = true

	position += 1
	code = charCodeAt(body, position + 1);
	position = readDigits(source, position, code);

    code = charCodeAt(body, position + 1);
  end

  if code == 69 or code == 101 then
    -- E e
    isFloat = true;

		position += 1
    	code = charCodeAt(body, position + 1);
    if code == 43 or code == 45 then
		-- + -
		position += 1
    	code = charCodeAt(body, position + 1);
	end
    position = readDigits(source, position, code);
	code = charCodeAt(body, position + 1);
  end

  -- Numbers cannot be followed by . or NameStart
  if code == 46 or isNameStart(code) then
    error(syntaxError(
      source,
      position,
      "Invalid number, expected digit but got: " .. printCharCode(code) .. "."
    ))
  end

  return Token.new(
    isFloat and TokenKind.FLOAT or TokenKind.INT,
    start,
    position,
    line,
    col,
    prev,
    slice(body, start - 1, position)
  );
end

local function readToken(lexer, prev)
	local source = lexer.source
	local body = source.body
	local bodyLength = string.len(body)

	local pos = prev._end

	while pos < bodyLength do

		local code = charCodeAt(body, pos)
		local line = lexer.line
		local col = pos - lexer.lineStart
		-- SourceCharacter
		if code == 0xfeff -- <BOM>
			or  code == 9 -- \t
			or code == 32 -- <space>
			or code == 44 -- ,
		then
			pos += 1
			continue
		elseif code == 10 -- \n
			then
			pos += 1
			lexer.line += 1
			lexer.lineStart = pos - 1
			continue
		elseif code == 13 -- \r
		then
			if charCodeAt(body, pos + 1) == 10 then
				pos += 2;
			else
				pos += 1;
			end
			lexer.line = lexer.line + 1;
			lexer.lineStart = pos - 1;
			continue
		elseif code == 33 -- !
		then
			return Token.new(TokenKind.BANG, pos, pos + 1, line, col, prev)
		elseif code == 35 -- #
		then
			return readComment(source, pos, line, col, prev)
		elseif code == 36 -- $
		then
			return Token.new(TokenKind.DOLLAR, pos, pos + 1, line, col, prev)
		elseif code == 38 -- &
		then
			return Token.new(TokenKind.AMP, pos, pos + 1, line, col, prev);
    	elseif code == 40 -- (
		then
			return Token.new(TokenKind.PAREN_L, pos, pos + 1, line, col, prev);
		elseif code == 41 -- )
		then
			return Token.new(TokenKind.PAREN_R, pos, pos + 1, line, col, prev);
		elseif code == 46 -- .
		then
			if
				charCodeAt(body, pos + 1) == 46 and
				charCodeAt(body, pos + 2) == 46
				then
					return Token.new(TokenKind.SPREAD, pos, pos + 3, line, col, prev);
				end
			-- don't need break because no case fall through in if statement
		elseif code ==  58 -- :
		then
			return Token.new(TokenKind.COLON, pos, pos + 1, line, col, prev)
		elseif code == 61 -- =
		then
			return Token.new(TokenKind.EQUALS, pos, pos + 1, line, col, prev)
		elseif code ==  64 --  @
		then
			return Token.new(TokenKind.AT, pos, pos + 1, line, col, prev)
		elseif code == 91 -- [
		then
			return Token.new(TokenKind.BRACKET_L, pos, pos + 1, line, col, prev)
		elseif code == 93 -- ]
		then
			return Token.new(TokenKind.BRACKET_R, pos, pos + 1, line, col, prev)
		elseif code == 123 -- {
		then
			return Token.new(TokenKind.BRACE_L, pos, pos + 1, line, col, prev)
		elseif code == 124 -- |
		then
			return Token.new(TokenKind.PIPE, pos, pos + 1, line, col, prev)
		elseif code == 125 -- }
		then
			return Token.new(TokenKind.BRACE_R, pos, pos + 1, line, col, prev)
		elseif code == 34 -- "
		then
		  if
		    charCodeAt(body, pos + 1) == 34 and
		    charCodeAt(body, pos + 2) == 34
		   then
		    return readBlockString(source, pos, line, col, prev, lexer)
		  end
		  return readString(source, pos, line, col, prev)
		elseif code == 45 -- -
			or code == 48 --  0
			or code == 49 --  1
			or code == 50 --  2
			or code == 51 --  3
			or code == 52 --  4
			or code == 53 --  5
			or code == 54 --  6
			or code == 55 --  7
			or code == 56 --  8
			or code == 57 --  9
		then
			return readNumber(source, pos, code, line, col, prev);
		elseif code == 65 --  A
			or code == 66 --  B
			or code == 67 --  C
			or code == 68 --  D
			or code == 69 --  E
			or code == 70 --  F
			or code == 71 --  G
			or code == 72 --  H
			or code == 73 --  I
			or code == 74 --  J
			or code == 75 --  K
			or code == 76 --  L
			or code == 77 --  M
			or code == 78 --  N
			or code == 79 --  O
			or code == 80 --  P
			or code == 81 --  Q
			or code == 82 --  R
			or code == 83 --  S
			or code == 84 --  T
			or code == 85 --  U
			or code == 86 --  V
			or code == 87 --  W
			or code == 88 --  X
			or code == 89 --  Y
			or code == 90 --  Z
			or code == 95 --  _
			or code == 97 --  a
			or code == 98 --  b
			or code == 99 --  c
			or code == 100 -- d
			or code == 101 -- e
			or code == 102 -- f
			or code == 103 -- g
			or code == 104 -- h
			or code == 105 -- i
			or code == 106 -- j
			or code == 107 -- k
			or code == 108 -- l
			or code == 109 -- m
			or code == 110 -- n
			or code == 111 -- o
			or code == 112 -- p
			or code == 113 -- q
			or code == 114 -- r
			or code == 115 -- s
			or code == 116 -- t
			or code == 117 -- u
			or code == 118 -- v
			or code == 119 -- w
			or code == 120 -- x
			or code == 121 -- y
			or code == 122 -- z
		then
			return readName(source, pos, line, col, prev);
		end
		error(syntaxError(source, pos, unexpectedCharacterMessage(code)))
	end

	local line = lexer.line
	local col = 1 + pos - lexer.lineStart
	return Token.new(TokenKind.EOF, bodyLength, bodyLength, line, col, prev);

end

local Lexer = {}
Lexer.__index = Lexer

function Lexer.new(source)
	local startOfFileToken = Token.new(TokenKind.SOF, 1, 1, 0, 0, nil)

	local self = {}
	self.source = source
	self.lastToken = startOfFileToken
	self.token = startOfFileToken
	self.line = 1
	self.lineStart = 0

	return setmetatable(self, Lexer)
end

function Lexer:advance()
	self.lastToken = self.token
	self.token = self:lookahead()
	return self.token
end

function Lexer:lookahead()
	local token = self.token
	if token.kind ~= TokenKind.EOF then
		repeat
			token = token.next or (function()
				token.next = readToken(self, token)
				return token.next
			end)()
		until (token and token.kind) ~= TokenKind.COMMENT


		-- if token.next == nil then
		-- 	token.next = readToken(self, token)
		-- 	token = token.next
		-- else
		-- 	token = token.next
		-- end

		-- while token ~= nil and token.kind == TokenKind.COMMENT do
		-- 	if token.next == nil then
		-- 		token.next = readToken(self, token)
		-- 	else
		-- 		token = token.next
		-- 	end
		-- end
	end

	return token
end

--[[
 * @internal
]]--
local function isPunctuatorTokenKind(kind)
  return (
    kind == TokenKind.BANG or
    kind == TokenKind.DOLLAR or
    kind == TokenKind.AMP or
    kind == TokenKind.PAREN_L or
    kind == TokenKind.PAREN_R or
    kind == TokenKind.SPREAD or
    kind == TokenKind.COLON or
    kind == TokenKind.EQUALS or
    kind == TokenKind.AT or
    kind == TokenKind.BRACKET_L or
    kind == TokenKind.BRACKET_R or
    kind == TokenKind.BRACE_L or
    kind == TokenKind.PIPE or
    kind == TokenKind.BRACE_R
  );
end


--[[
  Reads a block string token from the source file.
  """("?"?(\\"""|\\(?!=""")|[^"\\]))*"""
]]--
function readBlockString(
	source,
	start,
	line,
	col,
	prev,
	lexer
  )
	-- TODO
	return nil
end


--[[
  Reads a string token from the source file.
  "([^"\\\u000A\u000D]|(\\(u[0-9a-fA-F]{4}|["\\/bfnrt])))*"
]]--
function readString(
	source,
	start,
	line,
	col,
	prev
  )
	-- TODO
	return nil
end

return {
	Lexer = Lexer,
	isPunctuatorTokenKind = isPunctuatorTokenKind
}


