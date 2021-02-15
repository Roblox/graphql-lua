return function()
	local TestMatchers = script.Parent.TestMatchers
	local toEqual = require(TestMatchers.toEqual)
	local toArrayContains = require(TestMatchers.toArrayContains)
	local toHaveSameMembers = require(TestMatchers.toHaveSameMembers)
	local toObjectContain = require(TestMatchers.toObjectContain)
	local toBeOneOf = require(TestMatchers.toBeOneOf)
	local toThrow = require(TestMatchers.toThrow)
	local toBeNaN = require(TestMatchers.toBeNaN)

	beforeAll(function()
		-- ROBLOX FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
		-- use custom matchers added via `expect.extend`
		local expect: any = expect
		expect.extend({
			toEqual = toEqual,
			toArrayContains = toArrayContains,
			toHaveSameMembers = toHaveSameMembers,
			toObjectContain = toObjectContain,
			toBeOneOf = toBeOneOf,
			toThrow = toThrow,
			toBeNaN = toBeNaN,
		})
	end)
end
