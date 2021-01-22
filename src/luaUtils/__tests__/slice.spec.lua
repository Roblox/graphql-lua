return function()
	local luaUtils = script.Parent.Parent
	local root = luaUtils.Parent.Parent

	local slice = require(luaUtils.slice)
	local LuauPolyfill = require(root.Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array

	local sliceString = slice.sliceString

	describe("sliceString", function()
		it("returns a sliced string", function()
			local str = "hello"
			expect(sliceString(str, 2, 4)).to.equal("el")
			expect(sliceString(str, 3)).to.equal("llo")
		end)

		it("returns empty string when start index is below zero", function()
			local str = "4.123"
			expect(sliceString(str, -1, 4)).to.equal("")
		end)

		it("returns correct substring when start index is zero", function()
			local str = "4.123"
			expect(sliceString(str, 0, 4)).to.equal("4.1")
		end)

		it("returns correct substring when start index is one", function()
			local str = "4.123"
			expect(sliceString(str, 1, 4)).to.equal("4.1")
		end)

		it("returns a sliced table", function()
			local tbl = { 1, 2, 3, 4 }
			expect(Array.slice(tbl, 2)).toEqual({ 2, 3, 4 })
			expect(Array.slice(tbl, 1, 4)).toEqual({ 1, 2, 3 })
		end)

	end)

end
