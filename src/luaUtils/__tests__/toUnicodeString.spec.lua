return function()
	local luaUtils = script.Parent.Parent
	local toUnicodeString = require(luaUtils.toUnicodeString)

	describe("toUnicodeString",function()
		it("returns stringified character code",function()
			local actual = toUnicodeString(23)
			local expected = '"\\u00017"'
			expect(actual).to.equal(expected)
		end)
	end)
end
