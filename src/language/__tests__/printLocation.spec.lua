-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/printLocation-test.js

return function()

	describe("printSourceLocation", function()
		itSKIP("prints minified documents", function()
			-- const minifiedSource = new Source(
			-- 	'query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String){someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD...on THIRD_ERROR_HERE}}}',
			--   );

			--   const firstLocation = printSourceLocation(minifiedSource, {
			-- 	line: 1,
			-- 	column: minifiedSource.body.indexOf('FIRST_ERROR_HERE') + 1,
			--   });
			--   expect(firstLocation + '\n').to.equal(dedent`
			-- 	GraphQL request:1:53
			-- 	1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
			-- 	  |                                                     ^
			-- 	  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
			--   `);

			--   const secondLocation = printSourceLocation(minifiedSource, {
			-- 	line: 1,
			-- 	column: minifiedSource.body.indexOf('SECOND_ERROR_HERE') + 1,
			--   });
			--   expect(secondLocation + '\n').to.equal(dedent`
			-- 	GraphQL request:1:114
			-- 	1 | query SomeMinifiedQueryWithErrorInside($foo:String!=FIRST_ERROR_HERE$bar:String)
			-- 	  | {someField(foo:$foo bar:$bar baz:SECOND_ERROR_HERE){fieldA fieldB{fieldC fieldD.
			-- 	  |                                  ^
			-- 	  | ..on THIRD_ERROR_HERE}}}
			--   `);

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

		itSKIP("prints single digit line number with no padding", function()
			-- const result = printSourceLocation(
			-- 	new Source('*', 'Test', { line: 9, column: 1 }),
			-- 	{ line: 1, column: 1 },
			--   );

			--   expect(result + '\n').to.equal(dedent`
			-- 	Test:9:1
			-- 	9 | *
			-- 	  | ^
			--   `);
		end)

		itSKIP("prints an line numbers with correct padding", function()
			-- const result = printSourceLocation(
			-- 	new Source('*\n', 'Test', { line: 9, column: 1 }),
			-- 	{ line: 1, column: 1 },
			--   );

			--   expect(result + '\n').to.equal(dedent`
			-- 	Test:9:1
			-- 	 9 | *
			-- 	   | ^
			-- 	10 |
			--   `);
		end)
	end)
end
