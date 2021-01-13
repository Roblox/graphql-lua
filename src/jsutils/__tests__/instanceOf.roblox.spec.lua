-- ROBLOX deviation: no upstream tests

return function()
	local jsutils = script.Parent.Parent
	local instanceOf = require(jsutils.instanceOf)

	describe("instanceOf", function()

		local ParentClass = {}
		ParentClass.__index = ParentClass

		function ParentClass.new(message)

			local self = {}
			self.name = "Parent"
			self.message = message

			return setmetatable(self, ParentClass)
		end

		local ChildClass = setmetatable({}, { __index = ParentClass })
		ChildClass.__index = ChildClass

		function ChildClass.new(message)

			local self = ParentClass.new(message)
			self.name = "Child"

			return setmetatable(self, ChildClass)
		end

		it("returns false when passed nil", function()
			expect(instanceOf(nil, ParentClass)).to.equal(false)
		end)
		it("returns false when passed empty table", function()
			expect(instanceOf({}, ParentClass)).to.equal(false)
		end)

		it("returns true when passed instance class", function()

			local myParentClass = ParentClass.new("hello")

			expect(instanceOf(myParentClass, ParentClass)).to.equal(true)
		end)

		it("returns true when checking desecdent", function()

			local myChildClass = ChildClass.new("hello")

			expect(instanceOf(myChildClass, ParentClass)).to.equal(true)
		end)

	end)
end
