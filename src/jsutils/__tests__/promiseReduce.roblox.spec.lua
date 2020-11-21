return function()
	local jsutils = script.Parent.Parent
	local graphql = jsutils.Parent
	local Packages = graphql.Parent.Packages
	local Promise = require(Packages.Promise)
	local promiseReduce = require(jsutils.promiseReduce)

	describe("promiseReduce", function()
		it("should return the initial value when the list is empty", function()
			local initialValue = {}
			local result = promiseReduce({}, function()
				error("should not be called")
			end, initialValue)
			expect(result).to.equal(initialValue)
		end)

		it("should fold the list if the reducer never returns promises", function()
			local sum = promiseReduce({1, 2, 3}, function(sum, element)
				return sum + element
			end, 0)
			expect(sum).to.equal(6)
		end)

		it("should fold the list into a promise if the reducer returns at least a promise", function()
			local sum = promiseReduce({1, 2, 3}, function(sum, element)
				if element == 2 then
					return Promise.resolve(sum + element)
				else
					return sum + element
				end
			end, 0)
			expect(Promise.is(sum)).to.equal(true)
			expect(sum:getStatus()).to.equal(Promise.Status.Resolved)
			expect(sum:expect()).to.equal(6)
		end)

		it("should return the first rejected promise", function()
			local errorMessage = "foo"
			local sum = promiseReduce({1, 2, 3}, function(sum, element)
				if element == 2 then
					return Promise.reject(errorMessage)
				else
					return sum + element
				end
			end, 0)
			expect(Promise.is(sum)).to.equal(true)
			local status, rejection = sum:awaitStatus()
			expect(status).to.equal(Promise.Status.Rejected)
			expect(rejection).to.equal(errorMessage)
		end)
	end)
end
