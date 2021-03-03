-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/jsutils/__tests__/isIteratableObject-test.js
return function()

	-- ROBLOX deviation: utils
	local NaN = 0/0

	local isIteratableObject = require(script.Parent.Parent.isIteratableObject).isIteratableObject

	describe('isIteratableObject', function()

		it('should return `true` for collections', function()
			-- ROBLOX deviation: don't support empty variadic / [Symbol.iterator] / generator
			expect(isIteratableObject({})).to.equal(true)
			expect(isIteratableObject({1,2,3})).to.equal(true)

		end)

		it('should return `false` for non-collections', function()
			-- ROBLOX deviation: don't support Boolean / Number / Symbol.iterator
			expect(isIteratableObject(nil)).to.equal(false)
			expect(isIteratableObject(nil)).to.equal(false)
			expect(isIteratableObject('ABC')).to.equal(false)
			expect(isIteratableObject('0')).to.equal(false)
			expect(isIteratableObject('')).to.equal(false)
			expect(isIteratableObject(1)).to.equal(false)
			expect(isIteratableObject(0)).to.equal(false)
			expect(isIteratableObject(NaN)).to.equal(false)
			expect(isIteratableObject(true)).to.equal(false)
			expect(isIteratableObject(false)).to.equal(false)
			expect(isIteratableObject({iterable = true})).to.equal(false)

		end)
	end)

end