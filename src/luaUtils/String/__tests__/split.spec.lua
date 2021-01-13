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
	end)
end
