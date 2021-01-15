-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/__tests__/genFuzzStrings-test.js

return function()
	local genFuzzStrings = require(script.Parent.Parent.genFuzzStrings)
	local function expectFuzzStrings(options)
		local gen = genFuzzStrings(options)
		-- create an array from generator
		local arr = {}
		local item = gen.next()
		while item ~= nil do
			table.insert(arr, item)
			item = gen.next()
		end

		-- ROBLOX deviation - because of how TestEZ works we can't use expect in here
		return arr
	end

	describe("genFuzzStrings", function()
		it("always provide empty string", function()
			expect(expectFuzzStrings({
				allowedChars = {},
				maxLength = 0,
			})).toEqual({ "" })

			expect(expectFuzzStrings({ allowedChars = {}, maxLength = 1 })).toEqual({ "" })
			expect(expectFuzzStrings({ allowedChars = { "a" }, maxLength = 0 })).toEqual({ "" })
		end)

		it("generate strings with single character", function()
			expect(expectFuzzStrings({ allowedChars = { "a" }, maxLength = 1 })).toEqual({
				"",
				"a",
			})

			expect(expectFuzzStrings({ allowedChars = { "a", "b", "c" }, maxLength = 1 })).toEqual({
				"",
				"a",
				"b",
				"c",
			})
		end)

		it("generate strings with multiple character", function()
			expect(expectFuzzStrings({ allowedChars = { "a" }, maxLength = 2 })).toEqual({
				"",
				"a",
				"aa",
			})

			expect(expectFuzzStrings({ allowedChars = { "a", "b", "c" }, maxLength = 2 })).toEqual({
				"",
				"a",
				"b",
				"c",
				"aa",
				"ab",
				"ac",
				"ba",
				"bb",
				"bc",
				"ca",
				"cb",
				"cc",
			})
		end)

		it("generate strings longer than possible number of characters", function()
			expect(expectFuzzStrings({ allowedChars = { "a", "b" }, maxLength = 3 })).toEqual({
				"",
				"a",
				"b",
				"aa",
				"ab",
				"ba",
				"bb",
				"aaa",
				"aab",
				"aba",
				"abb",
				"baa",
				"bab",
				"bba",
				"bbb",
			})
		end)
	end)
end
