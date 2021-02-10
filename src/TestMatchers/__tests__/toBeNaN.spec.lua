return function()
	local toBeNaN = require(script.Parent.Parent.toBeNaN)
	local NaN = 0 / 0

	describe("toBeNaN", function()

		it("should fail when passed a number", function()
			local result = toBeNaN(1)

			expect(result.pass).to.equal(false)
			expect(result.message).to.equal("expected: NaN (number), got: \"1\" (number) instead")
		end)

		it("should pass if passed NaN", function()
			local result = toBeNaN(NaN)

			expect(result.pass).to.equal(true)
		end)

	end)
end
