return function()
	local jsutils = script.Parent.Parent
	local invariant = require(jsutils.invariant)

	describe("invariant", function()
		it("throws on false conditions", function()
			expect(function()
				return invariant(false, "Oops!")
			end).to.throw("Oops!")
		end)

		it("use default error message", function()
			expect(function()
				return invariant(false)
			end).to.throw("Unexpected invariant triggered.")
		end)
	end)
end
