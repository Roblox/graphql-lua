return function()
	local jsutils = script.Parent.Parent
	local identityFunc = require(jsutils.identityFunc)

	describe("identityFunc", function()
		it("returns the first argument it receives", function()
			expect(identityFunc()).to.equal(nil)
			expect(identityFunc(nil)).to.equal(nil)

			local obj = {}
			expect(identityFunc(obj)).to.equal(obj)
		end)
	end)
end
