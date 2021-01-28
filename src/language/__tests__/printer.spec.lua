-- upstream: https://github.com/graphql/graphql-js/blob/661ff1a6b591eea1e7a7e7c9e6b8b2dcfabf3bd7/src/language/__tests__/printer-test.js

return function()
	local dedent = require(script.Parent.Parent.Parent.__testUtils__.dedent)
	local kitchenSinkQuery = require(script.Parent.Parent.Parent.__testUtils__.kitchenSinkQuery)

	local parse = require(script.Parent.Parent.parser).parse
	local print_ = require(script.Parent.Parent.printer).print

	local inspect = require(script.Parent.Parent.Parent.TestMatchers.inspect)
	describe("Printer: Query document", function()
		it("does not alter ast", function()
			-- ROBLOX deviation: no JSON.stringify in Lua. Using inspect instead
			local ast = parse(kitchenSinkQuery)
			local astBefore = inspect(ast)
			print_(ast)
			expect(inspect(ast)).toEqual(astBefore)
		end)

		it("prints minimal ast", function()
			local ast = { kind = "Field", name = { kind = "Name", value = "foo" } }
			expect(print_(ast)).to.equal("foo")
		end)

		it("produces helpful error messages", function()
			local badAST = { random = "Data" }

			-- $FlowExpectedError[incompatible-call]
			expect(function()
				print_(badAST)
			end).to.throw("Invalid AST Node: { random: \"Data\" }.")
		end)

		it("correctly prints non-query operations without name", function()
			local queryASTShorthanded = parse("query { id, name }")
			expect(print_(queryASTShorthanded)).to.equal(dedent([[
              {
                id
                name
              }
			]]))

			local mutationAST = parse("mutation { id, name }")
			expect(print_(mutationAST)).to.equal(dedent([[
				mutation {
				  id
				  name
				}
			]]))

			local queryASTWithArtifacts = parse("query ($foo: TestType) @testDirective { id, name }")
			expect(print_(queryASTWithArtifacts)).to.equal(dedent([[
				query ($foo: TestType) @testDirective {
				  id
				  name
				}
			]]))

			local mutationASTWithArtifacts = parse("mutation ($foo: TestType) @testDirective { id, name }")
			expect(print_(mutationASTWithArtifacts)).to.equal(dedent([[
				mutation ($foo: TestType) @testDirective {
				  id
				  name
				}
			]]))
		end)

		it("prints query with variable directives", function()
			local queryASTWithVariableDirective = parse("query ($foo: TestType = {a: 123} @testDirective(if: true) @test) { id }")
			expect(print_(queryASTWithVariableDirective)).to.equal(dedent([[
				query ($foo: TestType = {a: 123} @testDirective(if: true) @test) {
				  id
				}
			]]))
		end)

		it("keeps arguments on one line if line is short (<= 80 chars)", function()
			local printed = print_(parse("{trip(wheelchair:false arriveBy:false){dateTime}}"))

			expect(printed).to.equal(dedent([[
				{
				  trip(wheelchair: false, arriveBy: false) {
				    dateTime
				  }
				}
			]]))
		end)

		it("puts arguments on multiple lines if line is long (> 80 chars)", function()
			local printed = print_(parse("{trip(wheelchair:false arriveBy:false includePlannedCancellations:true transitDistanceReluctance:2000){dateTime}}"))

			expect(printed).to.equal(dedent([[
				{
				  trip(
				    wheelchair: false
				    arriveBy: false
				    includePlannedCancellations: true
				    transitDistanceReluctance: 2000
				  ) {
				    dateTime
				  }
				}
			]]))
		end)

		it("Experimental: prints fragment with variable directives", function()
			local queryASTWithVariableDirective = parse(
				"fragment Foo($foo: TestType @test) on TestType @testDirective { id }",
				{
					experimentalFragmentVariables = true,
				}
			)
			expect(print_(queryASTWithVariableDirective)).to.equal(dedent([[
				fragment Foo($foo: TestType @test) on TestType @testDirective {
				  id
				}
			]]))
		end)

		it("Experimental: correctly prints fragment defined variables", function()
			local fragmentWithVariable = parse(
				[[
				fragment Foo($a: ComplexType, $b: Boolean = false) on TestType {
				  id
				}
			]],
				{ experimentalFragmentVariables = true }
			)
			expect(print_(fragmentWithVariable)).to.equal(dedent([[
				fragment Foo($a: ComplexType, $b: Boolean = false) on TestType {
				  id
				}
			]]))
		end)

		it("prints kitchen sink", function()
			local printed = print_(parse(kitchenSinkQuery))

			expect(printed).to.equal(
				-- $FlowFixMe[incompatible-call]
				dedent([[
					query queryName($foo: ComplexType, $site: Site = MOBILE) @onQuery {
					  whoever123is: node(id: [123, 456]) {
					    id
					    ... on User @onInlineFragment {
					      field2 {
					        id
					        alias: field1(first: 10, after: $foo) @include(if: $foo) {
					          id
					          ...frag @onFragmentSpread
					        }
					      }
					    }
					    ... @skip(unless: $foo) {
					      id
					    }
					    ... {
					      id
					    }
					  }
					}

					mutation likeStory @onMutation {
					  like(story: 123) @onField {
					    story {
					      id @onField
					    }
					  }
					}

					subscription StoryLikeSubscription($input: StoryLikeSubscribeInput) @onSubscription {
					  storyLikeSubscribe(input: $input) {
					    story {
					      likers {
					        count
					      }
					      likeSentence {
					        text
					      }
					    }
					  }
					}

					fragment frag on Friend @onFragmentDefinition {
					  foo(
					    size: $size
					    bar: $b
					    obj: {key: "value", block: """
					      block string uses \"""
					    """}
					  )
					}

					{
					  unnamed(truthy: true, falsy: false, nullish: null)
					  query
					}

					{
					  __typename
					}
				]])
			)
		end)
	end)
end
