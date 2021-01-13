-- FIXME: roblox-cli has special, hard-coded types for TestEZ that break when we
-- use custom matchers added via `expect.extend`
--!nocheck
return function()
	local TestMatchers = script.Parent.TestMatchers
	local toEqual = require(TestMatchers.toEqual)
	local toArrayContains = require(TestMatchers.toArrayContains)
	local toObjectContain = require(TestMatchers.toObjectContain)

	beforeAll(function()
		expect.extend({
			toEqual = toEqual,
			toArrayContains = toArrayContains,
			toObjectContain = toObjectContain
		})
	end)
end
