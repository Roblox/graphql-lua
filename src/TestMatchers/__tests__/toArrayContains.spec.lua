return function()
	local toArrayContains = require(script.Parent.Parent.toArrayContains)

	describe("toArrayContains", function()


		it("should fail with a message printing full table values", function()
			local tbl = {{name="a"}}
			local item = {name="d"}
			local result = toArrayContains(tbl, item)

			expect(result.pass).to.equal(false)
			expect(result.message).to.equal("item not found in tbl")
		end)

		it("should pass if given value in array", function()
			local tbl = {{name="a"}, {name="b"}, {name="c"}}
			local item = {name="b"}
			local result = toArrayContains(tbl, item)

			expect(result.pass).to.equal(true)
		end)

	end)
end
