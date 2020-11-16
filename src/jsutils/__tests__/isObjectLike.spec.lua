return function()
	local jsutils = script.Parent.Parent

	local identityFunc = require(jsutils.identityFunc)
	local isObjectLike = require(jsutils.isObjectLike)

	describe("isObjectLike", function()
		it("should return `true` for objects", function()
			-- deviation: only tables can be considered objects
			expect(isObjectLike({})).to.equal(true)
			-- expect(isObjectLike(Object.create(nil))).to.equal(true)
			-- expect(isObjectLike(/a/)).to.equal(true)
			-- expect(isObjectLike({})).to.equal(true)
		end)

		it("should return `false` for non-objects", function()
			expect(isObjectLike(nil)).to.equal(false)
			expect(isObjectLike(nil)).to.equal(false)
			expect(isObjectLike(true)).to.equal(false)
			expect(isObjectLike("")).to.equal(false)
			expect(isObjectLike(identityFunc)).to.equal(false)
		end)
	end)
end
