-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/ast.js

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

-- ROBLOX deviation: don't implement since it's already slated for removal
-- @deprecated: Will be removed in v17
-- [Symbol.for('nodejs.util.inspect.custom')](): mixed {
--     return this.toJSON();
--   }

--[[*
 * Represents a range of characters represented by a lexical token
 * within a Source.
 ]]
local Token = {}
Token.__index = Token

function Token.new(
	kind,
	start: number,
	_end: number,
	line: number,
	column: number,
	prev,
	value: string
)
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

-- ROBLOX deviation: don't implement since it's already slated for removal
-- @deprecated: Will be removed in v17
-- [Symbol.for('nodejs.util.inspect.custom')](): mixed {
--     return this.toJSON();
--   }

local function isNode(maybeNode)
	return maybeNode ~= nil and typeof(maybeNode.kind) == "string"
end

return {
	Location = Location,
	Token = Token,
	isNode = isNode,
}
