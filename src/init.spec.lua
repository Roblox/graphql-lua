return function()
	local TestMatchers = script.Parent.TestMatchers
	local toEqual = require(TestMatchers.toEqual)
	local toArrayContains = require(TestMatchers.toArrayContains)
	local toObjectContain = require(TestMatchers.toObjectContain)
	local toBeOneOf = require(TestMatchers.toBeOneOf)

	beforeAll(function()
		-- ROBLOX FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
		-- use custom matchers added via `expect.extend`
		local expect: any = expect
		expect.extend({
			toEqual = toEqual,
			toArrayContains = toArrayContains,
			toObjectContain = toObjectContain,
			toBeOneOf = toBeOneOf,
		})
	end)
end
