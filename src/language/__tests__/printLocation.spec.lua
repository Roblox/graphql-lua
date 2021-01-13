-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/printLocation-test.js

return function()
	local languageWorkspace = script.Parent.Parent
	local srcWorkspace = languageWorkspace.Parent

	local Source = require(languageWorkspace.source).Source
	local printSourceLocation = require(languageWorkspace.printLocation).printSourceLocation
	local dedent = require(srcWorkspace.__testUtils__.dedent)
	describe("printSourceLocation", function()
		it("prints minified documents", function()
			local minifiedSource = Source.new("query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String){someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD...on THIRD_ERROR_HERE}}}")

			local firstLocation = printSourceLocation(minifiedSource, {
				line = 1,
				column = string.find(minifiedSource.body, "FIRST_ERROR_HERE", 1, true),
			})
			expect(firstLocation .. "\n").to.equal(dedent([[
				GraphQL request:1:53
				1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
				  |                                                     ^
				  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
			]]))

			local secondLocation = printSourceLocation(minifiedSource, {
				line = 1,
				column = string.find(minifiedSource.body, "SECOND_ERROR_HERE", 1, true),
			})
			expect(secondLocation .. "\n").to.equal(dedent([[
				GraphQL request:1:114
				1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
				  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
				  |                                  ^
				  | ..on THIRD_ERROR_HERE}}}
			]]))

			local thirdLocation = printSourceLocation(minifiedSource, {
				line = 1,
				column = string.find(minifiedSource.body, "THIRD_ERROR_HERE", 1, true),
			})
			expect("\n" .. thirdLocation .. "\n").to.equal("\n" .. dedent([[
				GraphQL request:1:166
				1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
				  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
				  | ..on THIRD_ERROR_HERE}}}
				  |      ^
			]]))

			--   const thirdLocation = printSourceLocation(minifiedSource, {
			-- 	line: 1,
			-- 	column: minifiedSource.body.indexOf('THIRD_ERROR_HERE') + 1,
			--   });
			--   expect(thirdLocation + '\n').to.equal(dedent`
			-- 	GraphQL request:1:166
			-- 	1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
			-- 	  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
			-- 	  | ..on THIRD_ERROR_HERE}}}
			-- 	  |      ^
			--   `);
		end)

		it("prints single digit line number with no padding", function()
			local result = printSourceLocation(
				Source.new("*", "Test", { line = 9, column = 1 }),
				{ line = 1, column = 1 }
			)

			expect(result .. "\n").to.equal(dedent([[
				Test:9:1
				9 | *
				  | ^
			]]))
		end)

		it("prints an line numbers with correct padding", function()
			local result = printSourceLocation(
				Source.new("*\n", "Test", { line = 9, column = 1 }),
				{ line = 1, column = 1 }
			)

			expect("\n" .. result .. "\n").to.equal("\n" .. dedent([[
				Test:9:1
				 9 | *
				   | ^
				10 |
			  ]]))
		end)
	end)
end