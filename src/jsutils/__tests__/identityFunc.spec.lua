-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/__tests__/identityFunc-test.js
return function()
	local jsutils = script.Parent.Parent
	local identityFunc = require(jsutils.identityFunc).identityFunc

	describe("identityFunc", function()
		it("returns the first argument it receives", function()
			expect(identityFunc()).to.equal(nil)
			expect(identityFunc(nil)).to.equal(nil)

			local obj = {}
			expect(identityFunc(obj)).to.equal(obj)
		end)
	end)
end
