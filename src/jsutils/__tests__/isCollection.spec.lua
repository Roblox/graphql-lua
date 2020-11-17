-- upstream: https://github.com/graphql/graphql-js/blob/ab329e9bd8abcaa9eac6d4fa793df9fd8989a3f6/src/jsutils/__tests__/isCollection-test.js
return function()
	local jsutils = script.Parent.Parent

	-- local identityFunc = require(jsutils.identityFunc)
	local isCollection = require(jsutils.isCollection)

	describe("isCollection", function()
		it("should return `true` for collections", function()
			expect(isCollection({})).to.equal(true)
			-- expect(isCollection(new Int8Array(1))).to.equal(true)

			-- expect(isCollection(new String('ABC'))).to.equal(true)

			local function getArguments(...)
				return {...}
			end

			expect(isCollection(getArguments())).to.equal(true)

			local arrayLike = {}

			arrayLike[1] = "Alpha"
			arrayLike[2] = "Bravo"
			arrayLike[3] = "Charlie"

			expect(isCollection(arrayLike)).to.equal(true)

			-- deviation: no iterators in Lua
			-- local iterator = {
			-- 	[Symbol.iterator] = identityFunc,
			-- }
			-- expect(isCollection(iterator)).to.equal(true)

			-- deviation: no generator functions in Lua
			-- local function generatorFunc()
			-- 	-- /* do nothing */
			-- end

			-- expect(isCollection(generatorFunc())).to.equal(true)

			-- -- // But generator function itself is not iteratable
			-- expect(isCollection(generatorFunc)).to.equal(false)
		end)

		-- deviation: some objects that do not apply in Lua have been
		-- commented, and since Lua tables are like maps, tables are
		-- considered a collection.
		it("should return `false` for non-collections", function()
			expect(isCollection(nil)).to.equal(false)
			-- expect(isCollection(undefined)).to.equal(false)

			expect(isCollection("ABC")).to.equal(false)
			expect(isCollection("0")).to.equal(false)
			expect(isCollection("")).to.equal(false)

			expect(isCollection(1)).to.equal(false)
			expect(isCollection(0)).to.equal(false)
			expect(isCollection(0/0)).to.equal(false)
			-- expect(isCollection(new Number(123))).to.equal(false)

			expect(isCollection(true)).to.equal(false)
			expect(isCollection(false)).to.equal(false)
			-- expect(isCollection(new Boolean(true))).to.equal(false)

			-- expect(isCollection({})).to.equal(false)
			-- expect(isCollection({iterable = true})).to.equal(false)

			-- local iteratorWithoutSymbol = { next = identityFunc }
			-- expect(isCollection(iteratorWithoutSymbol)).to.equal(false)

			-- deviation: no iterators in Lua
			-- local invalidIteratable = {
			-- 	[Symbol.iterator] = {next = identityFunc},
			-- }
			-- expect(isCollection(invalidIteratable)).to.equal(false)
		end)
	end)
end
