return function()
	local jsutils = script.Parent.Parent

	local suggestionList = require(jsutils.suggestionList)

	describe("suggestionList", function()
		local function expectSuggestions(input, options)
			return expect(suggestionList(input, options))
		end

		it("Returns results when input is empty", function()
			expectSuggestions("", {"a"}).to.deep.equal({"a"})
		end)

		it("Returns empty array when there are no options", function()
			expectSuggestions("input", {}).to.deep.equal({})
		end)

		it("Returns options with small lexical distance", function()
			expectSuggestions("greenish", {"green"}).to.deep.equal({"green"})
			expectSuggestions("green", {"greenish"}).to.deep.equal({"greenish"})
		end)

		it("Rejects options with distance that exceeds threshold", function()
			expectSuggestions("aaaa", {"aaab"}).to.deep.equal({"aaab"})
			expectSuggestions("aaaa", {"aabb"}).to.deep.equal({"aabb"})
			expectSuggestions("aaaa", {"abbb"}).to.deep.equal({})

			expectSuggestions("ab", {"ca"}).to.deep.equal({})
		end)

		it("Returns options with different case", function()
			expectSuggestions("verylongstring", {"VERYLONGSTRING"}).to.deep.equal({
				"VERYLONGSTRING"
			})
			expectSuggestions("VERYLONGSTRING", {"verylongstring"}).to.deep.equal({
				"verylongstring",
			})
			expectSuggestions("VERYLONGSTRING", {"VeryLongString"}).to.deep.equal({
				"VeryLongString",
			})
		end)

		it("Returns options with transpositions", function()
			expectSuggestions("agr", {"arg"}).to.deep.equal({"arg"})
			expectSuggestions("214365879", {"123456789"}).to.deep.equal({"123456789"})
		end)

		it("Returns options sorted based on lexical distance", function()
			expectSuggestions("abc", {"a", "ab", "abc"}).to.deep.equal({
				"abc",
				"ab",
				"a",
			})
		end)

		it("Returns options with the same lexical distance sorted lexicographically", function()
			expectSuggestions("a", {"az", "ax", "ay"}).to.deep.equal({
				"ax",
				"ay",
				"az",
			})
		end)
	end)
end
