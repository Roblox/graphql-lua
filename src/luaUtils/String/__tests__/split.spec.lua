return function()
	local split = require(script.Parent.Parent.split)
	describe("String.split", function()
		it("should split with single split pattern", function()
			local str = "The quick brown fox jumps over the lazy dog."
			expect(split(str, " ")).toEqual({
				"The",
				"quick",
				"brown",
				"fox",
				"jumps",
				"over",
				"the",
				"lazy",
				"dog.",
			})
		end)

		it("should split with table with single split pattern", function()
			local str = "The quick brown fox jumps over the lazy dog."
			expect(split(str, { " " })).toEqual({
				"The",
				"quick",
				"brown",
				"fox",
				"jumps",
				"over",
				"the",
				"lazy",
				"dog.",
			})
		end)

		it("should split with table with multiple split pattern", function()
			local str = "one\ntwo\rthree\r\nfour"
			expect(split(str, { "\r\n", "\r", "\n" })).toEqual({ "one", "two", "three", "four" })
		end)

		it("should include empty string in the beginning", function()
			local str = "babc"
			expect(split(str, { "b" })).toEqual({ "", "a", "c" })
		end)

		it("should include empty string in the end", function()
			local str = "abcb"
			expect(split(str, { "b" })).toEqual({ "a", "c", "" })
		end)

		it("should include whole string if no match", function()
			local str = "abc"
			expect(split(str, { "d" })).toEqual({ "abc" })
		end)

		it('should split the string containing multi-byte character', function()
			local str = '\u{FEFF}|# "Comment" string\n,|'
			local spl = split(str, { "\r\n", "\n", "\r" })
			expect(spl).toEqual({
				'\u{FEFF}|# "Comment" string', ',|'
			})
		end)
	end)
end
