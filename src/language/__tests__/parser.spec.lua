-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/parser-test.js

return function()
	local languageWorkspace = script.Parent.Parent
	local srcWorkspace = languageWorkspace.Parent

	local dedent = require(srcWorkspace.__testUtils__.dedent)

	local inspect = require(srcWorkspace.jsutils.inspect)

	local Kind = require(languageWorkspace.kinds).Kind
	local Source = require(languageWorkspace.source).Source
	local TokenKind = require(languageWorkspace.tokenKind).TokenKind
	local parser = require(languageWorkspace.parser)
	local parse = parser.parse
	local parseValue = parser.parseValue

	local kitchenSinkQuery = require(srcWorkspace.__fixtures__).kitchenSinkQuery

	local UtilArray = require(srcWorkspace.luaUtils.Array)

	-- ROBLOX deviation: expect cannot be called unless inside of an it
	-- ROBLOX deviation: pass expect into this function and use local scope
	local function expectSyntaxError(expect_, text: string)
		local f = function()
			return parse(text)
		end
		local caughtError
		expect_(f).to.throw()
		xpcall(f, function(e)
			caughtError = e
		end)
		return expect_(caughtError)
	end
	local toJSONDeep = require(script.Parent.toJSONDeep)

	describe("Parser", function()
		it("asserts that a source to parse was provided", function()
			expect(function()
				parse()
			end).to.throw("Must provide Source. Received: nil.")
		end)

		it("asserts that an invalid source to parse was provided", function()
			expect(function()
				parse({})
			end).to.throw("Must provide Source. Received: [].")
		end)

		it("parse provides useful errors", function()
			local caughtError
			xpcall(function()
				parse("{")
			end, function(e)
				caughtError = e
			end)

			expect(caughtError).toObjectContain({
				message = "Syntax Error: Expected Name, found <EOF>.",
				positions = { 2 },
				locations = { { line = 1, column = 2 } },
			})

			expect(tostring(caughtError) .. "\n").to.equal(dedent([[
				Syntax Error: Expected Name, found <EOF>.

				GraphQL request:1:2
				1 | {
				  |  ^
			]]))

			expectSyntaxError(
				expect,
				UtilArray.join(
					{
						"",
						"      { ...MissingOn }",
						"      fragment MissingOn Type",
						"    ",
					},
					"\n"
				)
			).toObjectContain({
				message = "Syntax Error: Expected \"on\", found Name \"Type\".",
				locations = { { line = 3, column = 26 } },
			})

			expectSyntaxError(expect, "{ field: {} }").toObjectContain({
				message = "Syntax Error: Expected Name, found \"{\".",
				locations = { { line = 1, column = 10 } },
			})

			expectSyntaxError(expect, "notAnOperation Foo { field }").toObjectContain({
				message = "Syntax Error: Unexpected Name \"notAnOperation\".",
				locations = { { line = 1, column = 1 } },
			})

			expectSyntaxError(expect, "...").toObjectContain({
				message = "Syntax Error: Unexpected \"...\".",
				locations = { { line = 1, column = 1 } },
			})

			expectSyntaxError(expect, "{ \"\"").toObjectContain({
				message = "Syntax Error: Expected Name, found String \"\".",
				locations = { { line = 1, column = 3 } },
			})
		end)

		it("parse provides useful error when using source", function()
			local caughtError
			xpcall(function()
				parse(Source.new("query", "MyQuery.graphql"))
			end, function(e)
				caughtError = e
			end)
			expect(tostring(caughtError) .. "\n").to.equal(dedent([[
				Syntax Error: Expected "{", found <EOF>.

				MyQuery.graphql:1:6
				1 | query
				  |      ^
			]]))
		end)

		it("parses variable inline values", function()
			expect(function()
				parse("{ field(complex: { a: { b: [ $var ] } }) }")
			end).never.to.throw()
		end)

		it("parses constant default values", function()
			expectSyntaxError(expect, "query Foo($x: Complex = { a: { b: [ $var ] } }) { field }").toObjectContain({
				message = "Syntax Error: Unexpected \"$\".",
				locations = { { line = 1, column = 37 } },
			})
		end)

		it("parses variable definition directives", function()
			expect(function()
				parse("query Foo($x: Boolean = false @bar) { field }")
			end).never.to.throw()
		end)

		it("does not accept fragments named \"on\"", function()
			expectSyntaxError(expect, "fragment on on on { on }").toObjectContain({
				message = "Syntax Error: Unexpected Name \"on\".",
				locations = { { line = 1, column = 10 } },
			})
		end)

		it("does not accept fragments spread of \"on\"", function()
			expectSyntaxError(expect, "{ ...on }").toObjectContain({
				message = "Syntax Error: Expected Name, found \"}\".",
				locations = { { line = 1, column = 9 } },
			})
		end)

		it("parses multi-byte characters", function()
			-- // Note: \u0A0A could be naively interpreted as two line-feed chars.
			local ast = parse(UtilArray.join(
				{
					"",
					"      # This comment has a \u{0A0A} multi-byte character.",
					"      { field(arg: \"Has a \u{0A0A} multi-byte character.\") }",
					"",
				},
				"\n"
			))
			expect(ast.definitions[1].selectionSet.selections[1].arguments[1].value.value).to.equal("Has a \u{0A0A} multi-byte character.")
		end)

		it("parses kitchen sink", function()
			expect(function()
				parse(kitchenSinkQuery)
			end).never.to.throw()
		end)

		it("allows non-keywords anywhere a Name is allowed", function()
			local nonKeywords = {
				"on",
				"fragment",
				"query",
				"mutation",
				"subscription",
				"true",
				"false",
			}
			for _, keyword in ipairs(nonKeywords) do
				--   // You can't define or reference a fragment named `on`.
				local fragmentName = (function()
					if keyword ~= "on" then
						return keyword
					else
						return "a"
					end
				end)()
				local document = UtilArray.join(
					{
						"",
						"        query " .. keyword .. " {",
						"          ... " .. fragmentName,
						"          ... on " .. keyword .. " { field }",
						"        }",
						"        fragment " .. fragmentName .. " on Type {",
						"          " .. keyword .. "(" .. keyword .. ": $" .. keyword .. ")",
						"            @" .. keyword .. "(" .. keyword .. ": " .. keyword .. ")",
						"        }",
						"      ",
					},
					"\n"
				)
				expect(function()
					parse(document)
				end).never.to.throw()
			end
		end)

		it("parses anonymous mutation operations", function()
			expect(function()
				parse(UtilArray.join(
					{
						"",
						"      mutation {",
						"        mutationField",
						"      }",
						"    ",
					},
					"\n"
				))
			end).never.to.throw()
		end)

		it("parses anonymous subscription operations", function()
			expect(function()
				parse(UtilArray.join(
					{
						"",
						"      subscription {",
						"        subscriptionField",
						"      }",
						"    ",
					},
					"\n"
				))
			end).never.to.throw()
		end)

		it("parses named mutation operations", function()
			expect(function()
				parse(UtilArray.join(
					{
						"",
						"      mutation Foo {",
						"        mutationField",
						"      }",
						"    ",
					},
					"\n"
				))
			end).never.to.throw()
		end)

		it("parses named subscription operations", function()
			expect(function()
				parse(UtilArray.join(
					{
						"",
						"      subscription Foo {",
						"        subscriptionField",
						"      }",
						"    ",
					},
					"\n"
				))
			end).never.to.throw()
		end)

		it("creates ast", function()
			local result = parse(dedent([[
			  {
			    node(id: 4) {
			      id,
			      name
			    }
			  }
			]]))

			expect(toJSONDeep(result)).toObjectContain({
				kind = Kind.DOCUMENT,
				loc = { start = 1, _end = 42 },
				definitions = {
					{
						kind = Kind.OPERATION_DEFINITION,
						loc = { start = 1, _end = 41 },
						operation = "query",
						name = nil,
						variableDefinitions = {},
						directives = {},
						selectionSet = {
							kind = Kind.SELECTION_SET,
							loc = { start = 1, _end = 41 },
							selections = {
								{
									kind = Kind.FIELD,
									loc = { start = 5, _end = 39 },
									alias = nil,
									name = {
										kind = Kind.NAME,
										loc = { start = 5, _end = 9 },
										value = "node",
									},
									arguments = {
										{
											kind = Kind.ARGUMENT,
											name = {
												kind = Kind.NAME,
												loc = { start = 10, _end = 12 },
												value = "id",
											},
											value = {
												kind = Kind.INT,
												loc = { start = 14, _end = 15 },
												value = "4",
											},
											loc = { start = 10, _end = 15 },
										},
									},
									directives = {},
									selectionSet = {
										kind = Kind.SELECTION_SET,
										loc = { start = 17, _end = 39 },
										selections = {
											{
												kind = Kind.FIELD,
												loc = { start = 23, _end = 25 },
												alias = nil,
												name = {
													kind = Kind.NAME,
													loc = { start = 23, _end = 25 },
													value = "id",
												},
												arguments = {},
												directives = {},
												selectionSet = nil,
											},
											{
												kind = Kind.FIELD,
												loc = { start = 31, _end = 35 },
												alias = nil,
												name = {
													kind = Kind.NAME,
													loc = { start = 31, _end = 35 },
													value = "name",
												},
												arguments = {},
												directives = {},
												selectionSet = nil,
											},
										},
									},
								},
							},
						},
					},
				},
			})
		end)

		it("creates ast from nameless query without variables", function()
			local result = parse(dedent([[
			  query {
			    node {
			      id
			    }
			  }
			]]))

			expect(toJSONDeep(result)).toObjectContain({
				kind = Kind.DOCUMENT,
				loc = { start = 1, _end = 31 },
				definitions = {
					{
						kind = Kind.OPERATION_DEFINITION,
						loc = { start = 1, _end = 30 },
						operation = "query",
						name = nil,
						variableDefinitions = {},
						directives = {},
						selectionSet = {
							kind = Kind.SELECTION_SET,
							loc = { start = 7, _end = 30 },
							selections = {
								{
									kind = Kind.FIELD,
									loc = { start = 11, _end = 28 },
									alias = nil,
									name = {
										kind = Kind.NAME,
										loc = { start = 11, _end = 15 },
										value = "node",
									},
									arguments = {},
									directives = {},
									selectionSet = {
										kind = Kind.SELECTION_SET,
										loc = { start = 16, _end = 28 },
										selections = {
											{
												kind = Kind.FIELD,
												loc = { start = 22, _end = 24 },
												alias = nil,
												name = {
													kind = Kind.NAME,
													loc = { start = 22, _end = 24 },
													value = "id",
												},
												arguments = {},
												directives = {},
												selectionSet = nil,
											},
										},
									},
								},
							},
						},
					},
				},
			})
		end)

		it("allows parsing without source location information", function()
			local result = parse("{ id }", { noLocation = true })
			expect(result.loc).to.equal(nil)
		end)

		it("Experimental: allows parsing fragment defined variables", function()
			local document = "fragment a($v: Boolean = false) on t { f(v: $v) }"

			expect(function()
				parse(document, { experimentalFragmentVariables = true })
			end).never.to.throw()

			local caughtError
			xpcall(function()
				parse(document)
			end, function(e)
				caughtError = e
			end)
			expect(caughtError.message:match("Syntax Error")).to.be.ok() -- ROBLOX deviation: .to.throw('Syntax Error') doesn't work as expected
		end)

		it("contains location information that only stringifies start/end", function()
			local result = parse("{ id }")
			-- ROBLOX deviation: no JSON.stringify and node inspect in Lua
			expect(inspect(result.loc)).to.equal("{ start: 1, _end: 7 }")
		end)

		it("contains references to source", function()
			local source = Source.new("{ id }")
			local result = parse(source)

			expect(result.loc.source).to.equal(source)
		end)

		it("contains references to start and end tokens", function()
			local result = parse("{ id }")

			expect(result.loc.startToken.kind).to.equal(TokenKind.SOF)
			expect(result.loc.endToken.kind).to.equal(TokenKind.EOF)
		end)

		describe("parseValue", function()
			it("parses null value", function()
				local result = parseValue("null")

				expect(toJSONDeep(result)).toEqual(
					{
						kind = Kind.NULL,
						loc = { start = 1, _end = 5 }, -- ROBLOX deviation: indexes are 1-based
					}
				)
			end)

			it(
				"parses Int value",
				function() -- ROBLOX  deviation: additional test for parsing single integer value
					local result = parseValue("123")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.INT,
						loc = { start = 1, _end = 4 },
						value = "123",
					})
				end
			)

			it(
				"parses String value",
				function() -- ROBLOX  deviation: additional test for parsing single string value
					local result = parseValue("\"abc\"")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.STRING,
						loc = { start = 1, _end = 6 },
						value = "abc",
						block = false,
					})
				end
			)

			it(
				"parses empty list",
				function() -- ROBLOX  deviation: additional test for parsing empty list value
					local result = parseValue("[]")

					expect(toJSONDeep(result)).toEqual({
						kind = Kind.LIST,
						loc = { start = 1, _end = 3 },
						values = {},
					})
				end
			)

			it("parses list values", function()
				local result = parseValue("[123 \"abc\"]")
				expect(toJSONDeep(result)).toEqual(
					{
						kind = Kind.LIST,
						loc = { start = 1, _end = 12 }, -- ROBLOX deviation: indexes are 1-based
						values = {
							{
								kind = Kind.INT,
								loc = { start = 2, _end = 5 }, -- ROBLOX deviation: indexes are 1-based
								value = "123",
							},
							{
								kind = Kind.STRING,
								loc = { start = 6, _end = 11 }, -- ROBLOX deviation: indexes are 1-based
								value = "abc",
								block = false,
							},
						},
					}
				)
			end)

			it("parses block strings", function()
				local result = parseValue("[\"\"\"long\"\"\" \"short\"]")
				expect(toJSONDeep(result)).toEqual({
					kind = Kind.LIST,
					loc = { start = 1, _end = 21 },
					values = {
						{
							kind = Kind.STRING,
							loc = { start = 2, _end = 12 },
							value = "long",
							block = true,
						},
						{
							kind = Kind.STRING,
							loc = { start = 13, _end = 20 },
							value = "short",
							block = false,
						},
					},
				})
			end)
		end)
	end)
end
