return function()
	local includes = require(script.Parent.Parent.includes)

	describe("Array - includes", function()
		it("should return true when array includes a value", function()
			expect(includes({ 1, 2, 3 }, 1)).to.equal(true)
			expect(includes({ 1, 2, 3 }, 2)).to.equal(true)
			expect(includes({ 1, 2, 3 }, 3)).to.equal(true)
		end)

		it("should return false when array doesn't includes a value", function()
			expect(includes({ 1, 2, 3 }, 4)).to.equal(false)
			expect(includes({ 1, 2, 3 }, 5)).to.equal(false)
			expect(includes({ 1, 2, 3 }, 6)).to.equal(false)
		end)

		it("should compare objects by reference", function()
			local a, b, c = { "a" }, { "b" }, { "c" }
			expect(includes({ a, b, c }, a)).to.equal(true)
			expect(includes({ a, b, c }, b)).to.equal(true)
			expect(includes({ a, b, c }, c)).to.equal(true)

			expect(includes({ a, b, c }, { "a" })).to.equal(false)
			expect(includes({ a, b, c }, { "b" })).to.equal(false)
			expect(includes({ a, b, c }, { "c" })).to.equal(false)
		end)
	end)
end
