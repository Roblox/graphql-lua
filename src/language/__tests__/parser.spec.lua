return function()
	local parser = require(script.Parent.Parent.parser)
	local parse = parser.parse
	-- local parseValue = parser.parseValue
	-- local parseType = parser.parseType

	-- local function expectSyntaxError(text: string)
	--     return expect(function() return parse(text) end).to.throw()
	-- end

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

		-- deviation: missing tests
	end)
end
