-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/error/__tests__/formatError-test.js

return function()

	local errorWorkspace = script.Parent.Parent
	local formatError = require(errorWorkspace.formatError).formatError
	local GraphQLErrorModule = require(errorWorkspace.GraphQLError)
	local GraphQLError = GraphQLErrorModule.GraphQLError

	describe("formatError: default error formatter", function()

		it("uses default message", function()
			local e = GraphQLError.new()

			expect(formatError(e)).toEqual({
				message = "An unknown error occurred.",
				locations = nil,
				path = nil,
			})
		end)

		it("includes path", function()
			local e = GraphQLError.new("msg", nil, nil, nil, {
				"path",
				3,
				"to",
				"field",
			})

			expect(formatError(e)).toEqual({
				message = "msg",
				locations = nil,
				path = { "path", 3, "to", "field" },
			})
		end)

		it("includes extension fields", function()
			local e = GraphQLError.new("msg", nil, nil, nil, nil, nil, {
				foo = "bar",
			})

			expect(formatError(e)).toEqual({
				message = "msg",
				locations = nil,
				path = nil,
				extensions = { foo = "bar" },
			})
		end)

		it("rejects nil error", function()
			expect(function()
				return formatError(nil)
			end).to.throw("Received nil error")
		end)

	end)
end
