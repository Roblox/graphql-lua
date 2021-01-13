-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/ast.js
--!nolint FunctionUnused

local language = script.Parent
local src = language.Parent

local defineInspect = require(src.jsutils.defineInspect)

local Location = {}
Location.__index = Location

function Location.new(startToken, endToken, source)
	local self = {}
	self.start = startToken.start
	self._end = endToken._end
	self.startToken = startToken
	self.endToken = endToken
	self.source = source

	return setmetatable(self, Location)
end

function Location:toJSON()
	return { start = self.start, _end = self._end }
end

-- `Print a simplified form when appearing in `inspect` and `util.inspect`.
defineInspect(Location)

local Token = {}
Token.__index = Token

function Token.new(kind, start, _end, line, column, prev, value)
	local self = {}
	self.kind = kind
	self.start = start
	self._end = _end
	self.line = line
	self.column = column
	self.value = value
	self.prev = prev
	self.next = nil

	return setmetatable(self, Token)
end

function Token:toJSON()
	return {
		kind = self.kind,
		value = self.value,
		line = self.line,
		column = self.column,
	}
end

-- Print a simplified form when appearing in `inspect` and `util.inspect`.
defineInspect(Token)

local function isNode(maybeNode)
	return maybeNode ~= nil and typeof(maybeNode.kind) == "string"
end

return {
	Location = Location,
	Token = Token,
	isNode = isNode,
}
