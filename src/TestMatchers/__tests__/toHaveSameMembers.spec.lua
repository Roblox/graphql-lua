return function()
	local toHaveSameMembers = require(script.Parent.Parent.toHaveSameMembers)

	describe("toHaveSameMembers", function()

		it("should fail if different length", function()
			local arrA = { { name = "a" } }
			local arrB = { { name = "a" }, { name = "b" } }
			local result = toHaveSameMembers(arrA, arrB)

			expect(result.pass).to.equal(false)
			expect(result.message).to.equal("Received array length 1 / expected length 2")
		end)

		it("should fail if items are different", function()
			local arrA = { { name = "a" } }
			local arrB = { { name = "b" } }
			local result = toHaveSameMembers(arrA, arrB)

			expect(result.pass).to.equal(false)
			expect(result.message).to.equal([[Expected item {
  name = "a"
} to be in Array { {
    name = "b"
  } }]])
		end)

		it("should pass if same items in different order", function()
			local arrA = { { name = "b" }, { name = "a" } }
			local arrB = { { name = "a" }, { name = "b" } }
			local result = toHaveSameMembers(arrA, arrB)

			expect(result.pass).to.equal(true)
		end)

	end)
end
