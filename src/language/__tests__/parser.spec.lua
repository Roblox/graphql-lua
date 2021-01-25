return function()

	local Kind = require(script.Parent.Parent.kinds).Kind
	local parser = require(script.Parent.Parent.parser)
	local parse = parser.parse
	local parseValue = parser.parseValue
	-- local parseType = parser.parseType

	-- local function expectSyntaxError(text: string)
	--     return expect(function() return parse(text) end).to.throw()
	-- end

	local toJSONDeep = require(script.Parent.toJSONDeep)

	describe("Parser", function()
		it("asserts that a source to parse was provided", function()
			expect(function()
				parse()
			end).to.throw("Must provide Source. Received: nil.")
		end)

		it("asserts that an invalid source to parse was provided", function()
			expect(function()
				parse({})
			end).to.throw("Must provide Source. Received: [].")
		end)

		itSKIP("parse provides useful errors", function()
			local caughtError
			local _ok, err = pcall(function()
				return parse("{")
			end)
			if not _ok then
				caughtError = err
			end

			expect(caughtError).toObjectContain({
				message = "Syntax Error: Expected Name, found <EOF>.",
				positions = { 1 },
				locations = { { line = 1, column = 2 } },
			})
		end)

		describe("parseValue", function()
			it("parses null value", function()
				local result = parseValue("null")

				expect(toJSONDeep(result)).toEqual(
					{
						kind = Kind.NULL,
						loc = { start = 1, _end = 5 }, -- ROBLOX deviation: indexes are 1-based
					}
				)
			end)

			it(
				"parses Int value",
				function() -- ROBLOX  deviation: additional test for parsing single integer value
					local result = parseValue("123")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.INT,
						loc = { start = 1, _end = 4 },
						value = "123",
					})
				end
			)

			it(
				"parses String value",
				function() -- ROBLOX  deviation: additional test for parsing single string value
					local result = parseValue("\"abc\"")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.STRING,
						loc = { start = 1, _end = 6 },
						value = "abc",
						block = false,
					})
				end
			)

			it(
				"parses empty list",
				function() -- ROBLOX  deviation: additional test for parsing empty list value
					local result = parseValue("[]")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.LIST,
						loc = { start = 1, _end = 3 },
						values = {},
					})
				end
			)

			it("parses list values", function()
				local result = parseValue("[123 \"abc\"]")
				expect(toJSONDeep(result)).toEqual(
					{
						kind = Kind.LIST,
						loc = { start = 1, _end = 12 }, -- ROBLOX deviation: indexes are 1-based
						values = {
							{
								kind = Kind.INT,
								loc = { start = 2, _end = 5 }, -- ROBLOX deviation: indexes are 1-based
								value = "123",
							},
							{
								kind = Kind.STRING,
								loc = { start = 6, _end = 11 }, -- ROBLOX deviation: indexes are 1-based
								value = "abc",
								block = false,
							},
						},
					}
				)
			end)

			it("parses block strings", function()
				local result = parseValue("[\"\"\"long\"\"\" \"short\"]")
				expect(toJSONDeep(result)).toEqual({
					kind = Kind.LIST,
					loc = { start = 1, _end = 21 },
					values = {
						{
							kind = Kind.STRING,
							loc = { start = 2, _end = 12 },
							value = "long",
							block = true,
						},
						{
							kind = Kind.STRING,
							loc = { start = 13, _end = 20 },
							value = "short",
							block = false,
						},
					},
				})
			end)
		end)
	end)
end
