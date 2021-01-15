-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/__tests__/inspectStr-test.js

return function()
	local inspectStr = require(script.Parent.Parent.inspectStr)

	describe("inspectStr", function()
		-- ROBLOX deviation: Lua has only nil value instead of null & undefined
		it("handles nil values", function()
			expect(inspectStr(nil)).to.equal("nil")
		end)

		it("correctly print various strings", function()
			expect(inspectStr("")).to.equal("``")
			expect(inspectStr("a")).to.equal("`a`")
			expect(inspectStr("\"")).to.equal("`\"`")
			expect(inspectStr("'")).to.equal("`'`")
			expect(inspectStr("\\\"")).to.equal("`\\\"`")
		end)
	end)
end
