-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/__tests__/identityFunc-test.js
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
