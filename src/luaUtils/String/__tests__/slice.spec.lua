return function()
	local slice = require(script.Parent.Parent.slice)

	describe("String - slice", function()

		it("returns a sliced string", function()
			local str = "hello"
			expect(slice(str, 2, 4)).to.equal("el")
			expect(slice(str, 3)).to.equal("llo")
		end)

		it("returns empty string when start index is below zero", function()
			local str = "4.123"
			expect(slice(str, -1, 4)).to.equal("")
		end)

		it("returns correct substring when start index is zero", function()
			local str = "4.123"
			expect(slice(str, 0, 4)).to.equal("4.1")
		end)

		it("returns correct substring when start index is one", function()
			local str = "4.123"
			expect(slice(str, 1, 4)).to.equal("4.1")
		end)

		it("retruns empty string when start position is greater than str length", function()
			local str = "4.123"
			expect(slice(str, 7, 4)).to.equal("")
		end)

		it("retruns full string when end position undefined", function()
			local str = "4.123"
			expect(slice(str, 1)).to.equal("4.123")
		end)

		it("retruns full string when end position is greater than str length", function()
			local str = "4.123"
			expect(slice(str, 1, 99)).to.equal("4.123")
		end)

		it("handle chars above 7-bit ascii", function()

			-- two bytes
			-- first byte (81)  - has high bit set
			-- second byte (23) - must have second byte
			local body = "\u{8123}a"

			expect(slice(body, 1, 2)).to.equal("\u{8123}")
			expect(slice(body, 2, 3)).to.equal("a")

		end)

	end)

end
