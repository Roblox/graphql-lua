-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/source.js

local language = script.Parent
local src = language.Parent

local inspect = require(src.jsutils.inspect)
local devAssert = require(src.jsutils.devAssert)

local symbols = require(src.polyfill.symbols)
local SYMBOL_TO_STRING_TAG = symbols.SYMBOL_TO_STRING_TAG

-- /**
--  * A representation of source input to GraphQL. The `name` and `locationOffset` parameters are
--  * optional, but they are useful for clients who store GraphQL documents in source files.
--  * For example, if the GraphQL input starts at line 40 in a file named `Foo.graphql`, it might
--  * be useful for `name` to be `"Foo.graphql"` and location to be `{ line: 40, column: 1 }`.
--  * The `line` and `column` properties in `locationOffset` are 1-indexed.
--  */
local Source = {}
Source.__index = Source

function Source.new(body, _name, _locationOffset)
	local name = _name or "GraphQL request"
	local locationOffset = _locationOffset or { line = 1, column = 1 }

	devAssert(
		typeof(body) == "string",
		"Body must be a string. Received: " .. inspect(body) .. "."
	)

	local self = {}
	self.body = body
	self.name = name
	self.locationOffset = locationOffset
	devAssert(
		self.locationOffset.line > 0,
		"line in locationOffset is 1-indexed and must be positive."
	)
	devAssert(
		self.locationOffset.column > 0,
		"column in locationOffset is 1-indexed and must be positive."
	)

	return setmetatable(self, Source)
end

Source[SYMBOL_TO_STRING_TAG] = "Source"

return {
	Source = Source,
}
