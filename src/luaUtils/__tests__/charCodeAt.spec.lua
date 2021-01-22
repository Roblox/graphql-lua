return function()
	local charCodeAt = require(script.Parent.Parent.charCodeAt)

	describe("charCodeAt", function()

		it("returns 97 for a", function()
			local body = "apple"
			local actual = charCodeAt(body, 1)
			expect(actual).to.equal(97)
		end)

		it("returns 97 for a when not the first character", function()
			local body = "_apple"
			local actual = charCodeAt(body, 2)
			expect(actual).to.equal(97)
		end)

		it(
			"returns 97 for a when not the first character and is the last character",
			function()
				local body = "_a"
				local actual = charCodeAt(body, 2)
				expect(actual).to.equal(97)
			end
		)

		it("returns special characters", function()
			-- test chars
			expect(charCodeAt(" ", 1)).to.equal(32)
			expect(charCodeAt(",", 1)).to.equal(44)

			-- test special chars
			expect(charCodeAt("\t", 1)).to.equal(9)
			expect(charCodeAt("\n", 1)).to.equal(10)

			-- test unicode (BOM)
			expect(0xfeff).to.equal(65279)

			local bomStringFromChar = utf8.char(0xfeff)
			local bomStringFromEncoding = "\u{feff}"

			expect(charCodeAt(bomStringFromChar, 1)).to.equal(65279)
			expect(charCodeAt(bomStringFromEncoding, 1)).to.equal(65279)

		end)

		it("handle chars above 7-bit ascii", function()

			-- two bytes
			-- first byte (81)  - has high bit set
			-- second byte (23) - must have second byte

			-- local body = utf8.char(0x8123) .. " foo"
			local body = "\u{8123}a"

			expect(charCodeAt(body, 1)).to.equal(0x8123)
			expect(charCodeAt(body, 2)).to.equal(97)
		end)

	end)

end
