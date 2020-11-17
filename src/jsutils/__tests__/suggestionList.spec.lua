-- upstream: https://github.com/graphql/graphql-js/blob/bbd8429b85594d9ee8cc632436e2d0f900d703ef/src/jsutils/__tests__/suggestionList-test.js
return function()
	local jsutils = script.Parent.Parent

	local suggestionList = require(jsutils.suggestionList)

	describe("suggestionList", function()
		local function expectSuggestions(input, options)
			return expect(suggestionList(input, options))
		end

		it("Returns results when input is empty", function()
			expectSuggestions("", {"a"}).toEqual({"a"})
		end)

		it("Returns empty array when there are no options", function()
			expectSuggestions("input", {}).toEqual({})
		end)

		it("Returns options with small lexical distance", function()
			expectSuggestions("greenish", {"green"}).toEqual({"green"})
			expectSuggestions("green", {"greenish"}).toEqual({"greenish"})
		end)

		it("Rejects options with distance that exceeds threshold", function()
			expectSuggestions("aaaa", {"aaab"}).toEqual({"aaab"})
			expectSuggestions("aaaa", {"aabb"}).toEqual({"aabb"})
			expectSuggestions("aaaa", {"abbb"}).toEqual({})

			expectSuggestions("ab", {"ca"}).toEqual({})
		end)

		it("Returns options with different case", function()
			expectSuggestions("verylongstring", {"VERYLONGSTRING"}).toEqual({
				"VERYLONGSTRING"
			})
			expectSuggestions("VERYLONGSTRING", {"verylongstring"}).toEqual({
				"verylongstring",
			})
			expectSuggestions("VERYLONGSTRING", {"VeryLongString"}).toEqual({
				"VeryLongString",
			})
		end)

		it("Returns options with transpositions", function()
			expectSuggestions("agr", {"arg"}).toEqual({"arg"})
			expectSuggestions("214365879", {"123456789"}).toEqual({"123456789"})
		end)

		it("Returns options sorted based on lexical distance", function()
			expectSuggestions("abc", {"a", "ab", "abc"}).toEqual({
				"abc",
				"ab",
				"a",
			})
		end)

		it("Returns options with the same lexical distance sorted lexicographically", function()
			expectSuggestions("a", {"az", "ax", "ay"}).toEqual({
				"ax",
				"ay",
				"az",
			})
		end)
	end)
end
