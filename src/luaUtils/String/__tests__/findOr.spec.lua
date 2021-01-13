return function()
	local findOr = require(script.Parent.Parent.findOr)

	describe("String.findOr", function()

		it("returns nil when not found", function()
			local str = "abc"
			local terms = { "d" }
			local match = findOr(str, terms)

			expect(match).to.equal(nil)
		end)

		it("returns matched element", function()
			local str = "abc"
			local terms = { "b" }
			local actual = findOr(str, terms)
			local expected = {
				index = 2,
				match = "b",
			}
			expect(actual.index).to.equal(expected.index)
			expect(actual.match).to.equal(expected.match)
		end)

		it("returns 2nd instance of matched element after start position", function()
			local str = "abcb"
			local terms = { "b" }
			local actual = findOr(str, terms, 3)
			local expected = {
				index = 4,
				match = "b",
			}
			expect(actual.index).to.equal(expected.index)
			expect(actual.match).to.equal(expected.match)
		end)

		it("returns if any items match", function()
			local str = "_rn_r_n"
			local terms = { "rn", "r", "n" }
			local actual = findOr(str, terms)
			local expected = {
				index = 2,
				match = "rn",
			}
			expect(actual.index).to.equal(expected.index)
			expect(actual.match).to.equal(expected.match)
		end)

		it("returns 2nd instance if any items match after start position", function()
			local str = "_rn_r_n"
			local terms = { "rn", "r", "n" }
			local actual = findOr(str, terms, 4)
			local expected = {
				index = 5,
				match = "r",
			}
			expect(actual.index).to.equal(expected.index)
			expect(actual.match).to.equal(expected.match)
		end)

		it("returns matched multiple characters", function()
			local str = "abbbc"
			local terms = { "b+" }
			local actual = findOr(str, terms)
			local expected = {
				index = 2,
				match = "bbb",
			}
			expect(actual.index).to.equal(expected.index)
			expect(actual.match).to.equal(expected.match)
		end)

	end)
end
