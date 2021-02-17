-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/execution/__tests__/sync-test.js

return function()
	local executionWorkspace = script.Parent.Parent
	local srcWorkspace = executionWorkspace.Parent

	-- ROBLOX deviation: utils
	local Object = require(srcWorkspace.Parent.Packages.LuauPolyfill).Object
	local Promise = require(srcWorkspace.Parent.Packages.Promise)

	local parse = require(srcWorkspace.language.parser).parse

	local validate = require(srcWorkspace.validation.validate).validate

	local GraphQLSchema = require(srcWorkspace.type.schema).GraphQLSchema
	local GraphQLString = require(srcWorkspace.type.scalars).GraphQLString
	local GraphQLObjectType = require(srcWorkspace.type.definition).GraphQLObjectType

	local graphqlSync = require(srcWorkspace.graphql).graphqlSync

	local executeImport = require(executionWorkspace.execute)
	local execute = executeImport.execute
	local executeSync = executeImport.executeSync

	local function _await(value, thenFunc, direct)
		if direct then
			return (function()
				if thenFunc then
					return thenFunc(value)
				end

				return value
			end)()
		end
		if not value or not value.andThen then
			value = Promise.resolve(value)
		end

		return (function()
			if thenFunc then
				return value:andThen(thenFunc)
			end

			return value
		end)()
	end
	local function _async(f: any)
		return function(...)
			local args = { ... }
			local ok, errorOrResult = pcall(function()
				return Promise.resolve(f(table.unpack(args)))
			end)
			if not ok then
				return Promise.reject(errorOrResult)
			end
			return errorOrResult
		end
	end

	describe("Execute: synchronously when possible", function()
		local schema = GraphQLSchema.new({
			query = GraphQLObjectType.new({
				name = "Query",
				fields = {
					syncField = {
						type = GraphQLString,
						resolve = function(rootValue)
							return rootValue
						end,
					},
					asyncField = {
						type = GraphQLString,
						resolve = function(rootValue)
							return Promise.resolve(rootValue)
						end,
					},
				},
			}),
			mutation = GraphQLObjectType.new({
				name = "Mutation",
				fields = {
					syncMutationField = {
						type = GraphQLString,
						resolve = function(rootValue)
							return rootValue
						end,
					},
				},
			}),
		})

		it("does not return a Promise for initial errors", function()
			local doc = "fragment Example on Query { syncField }"
			local result = execute({
				schema = schema,
				document = parse(doc),
				rootValue = "rootValue",
			})

			--[[
			--  ROBLOX deviation: .to.deep.equal matcher doesn't convert to .toEqual in this case as errors contain more fields than just message
			--]]
			expect(Object.keys(result)).toEqual({ "errors" })
			expect(result.errors).toHaveSameMembers(
				{
					{
						message = "Must provide an operation.",
					},
				},
				true
			)
		end)

		it("does not return a Promise if fields are all synchronous", function()
			local doc = "query Example { syncField }"
			local result = execute({
				schema = schema,
				document = parse(doc),
				rootValue = "rootValue",
			})

			expect(result).toEqual({
				data = {
					syncField = "rootValue",
				},
			})
		end)

		it("does not return a Promise if mutation fields are all synchronous", function()
			local doc = "mutation Example { syncMutationField }"
			local result = execute({
				schema = schema,
				document = parse(doc),
				rootValue = "rootValue",
			})

			expect(result).toEqual({
				data = {
					syncMutationField = "rootValue",
				},
			})
		end)

		itSKIP(
			"returns a Promise if any field is asynchronous",
			_async(function()
				local doc = "query Example { syncField, asyncField }"
				local result = execute({
					schema = schema,
					document = parse(doc),
					rootValue = "rootValue",
				})

				expect(result).to.be.instanceOf(Promise)

				return _await(result, function(_result)
					expect(_result).toEqual({
						data = {
							syncField = "rootValue",
							asyncField = "rootValue",
						},
					})
				end)
			end)
		)

		describe("executeSync", function()
			it("does not return a Promise for sync execution", function()
				local doc = "query Example { syncField }"
				local result = executeSync({
					schema = schema,
					document = parse(doc),
					rootValue = "rootValue",
				})

				expect(result).toEqual({
					data = {
						syncField = "rootValue",
					},
				})
			end)

			it("throws if encountering async execution", function()
				local doc = "query Example { syncField, asyncField }"

				expect(function()
					executeSync({
						schema = schema,
						document = parse(doc),
						rootValue = "rootValue",
					})
				end).toThrow("GraphQL execution failed to complete synchronously.")
			end)
		end)

		describe("graphqlSync", function()
			it("report errors raised during schema validation", function()
				local badSchema = GraphQLSchema.new({})
				local result = graphqlSync({
					schema = badSchema,
					source = "{ __typename }",
				})

				--[[
				--  ROBLOX deviation: .to.deep.equal matcher doesn't convert to .toEqual in this case as errors contain more fields than just message
				--]]
				expect(Object.keys(result)).toEqual({ "errors" })
				expect(result.errors).toHaveSameMembers(
					{
						{
							message = "Query root type must be provided.",
						},
					},
					true
				)
			end)

			it("does not return a Promise for syntax errors", function()
				local doc = "fragment Example on Query { { { syncField }"
				local result = graphqlSync({
					schema = schema,
					source = doc,
				})

				--[[
				--  ROBLOX deviation: .to.deep.equal matcher doesn't convert to .toEqual in this case as errors contain more fields than just message
				--]]
				expect(Object.keys(result)).toEqual({ "errors" })
				expect(result.errors).toHaveSameMembers(
					{
						{
							message = "Syntax Error: Expected Name, found \"{\".",
							locations = {
								{
									line = 1,
									column = 29,
								},
							},
						},
					},
					true
				)
			end)

			itSKIP("does not return a Promise for validation errors", function()
				local doc = "fragment Example on Query { unknownField }"
				local validationErrors = validate(schema, parse(doc))
				local result = graphqlSync({
					schema = schema,
					source = doc,
				})

				--[[
				--  ROBLOX deviation: .to.deep.equal matcher doesn't convert to .toEqual in this case as errors contain more fields than just message
				--]]
				expect(Object.keys(result)).toEqual({ "errors" })
				expect(result.errors).toHaveSameMembers(validationErrors, true)
			end)

			itSKIP("does not return a Promise for sync execution", function()
				local doc = "query Example { syncField }"
				local result = graphqlSync({
					schema = schema,
					source = doc,
					rootValue = "rootValue",
				})

				expect(result).toEqual({
					data = {
						syncField = "rootValue",
					},
				})
			end)

			itSKIP("throws if encountering async execution", function()
				local doc = "query Example { syncField, asyncField }"

				-- ROBLOX FIXME: integrate validation
				expect(function()
					graphqlSync({
						schema = schema,
						source = doc,
						rootValue = "rootValue",
					})
				end).toThrow("GraphQL execution failed to complete synchronously.")
			end)
		end)
	end)
end
