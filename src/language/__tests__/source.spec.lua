-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/source-test.js

return function()

	local Source = require(script.Parent.Parent.source).Source
	describe("Source", function()

		it("can be Object.toStringified", function()
			local source = Source.new("")

			expect(tostring(source)).toEqual("{table Source}")
		end)

		it("rejects invalid locationOffset", function()
			function createSource(locationOffset)
				return Source.new("", "", locationOffset)
			end

			expect(function()
				createSource({ line = 0, column = 1 })
			end).to.throw("line in locationOffset is 1-indexed and must be positive.")

			expect(function()
				createSource({ line = -1, column = 1 })
			end).to.throw("line in locationOffset is 1-indexed and must be positive.")

			expect(function()
				createSource({ line = 1, column = 0 })
			end).to.throw("column in locationOffset is 1-indexed and must be positive.")

			expect(function()
				createSource({ line = 1, column = -1 })
			end).to.throw("column in locationOffset is 1-indexed and must be positive.")
		end)
	end)
end
