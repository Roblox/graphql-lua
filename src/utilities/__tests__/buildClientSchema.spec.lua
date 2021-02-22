-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/__tests__/buildClientSchema-test.js

return function()
	local utilitiesWorkspace = script.Parent.Parent
	local srcWorkspace = utilitiesWorkspace.Parent

	local dedent = require(srcWorkspace.__testUtils__.dedent).dedent

	-- ROBLOX FIXME: require correct module when available
	local graphqlSync = function()
	end -- require(srcWorkspace.graphql).graphqlSync

	local GraphQLSchema = require(srcWorkspace.type.schema).GraphQLSchema

	local definitionImport = require(srcWorkspace.type.definition)
	local assertEnumType = definitionImport.assertEnumType
	local GraphQLObjectType = definitionImport.GraphQLObjectType
	local GraphQLEnumType = definitionImport.GraphQLEnumType
	local scalarsImport = require(srcWorkspace.type.scalars)
	local GraphQLInt = scalarsImport.GraphQLInt
	local GraphQLFloat = scalarsImport.GraphQLFloat
	local GraphQLString = scalarsImport.GraphQLString
	local GraphQLBoolean = scalarsImport.GraphQLBoolean
	local GraphQLID = scalarsImport.GraphQLID

	local printSchema = require(utilitiesWorkspace.printSchema).printSchema
	local buildSchema = require(utilitiesWorkspace.buildASTSchema).buildSchema
	local buildClientSchema = require(utilitiesWorkspace.buildClientSchema).buildClientSchema
	-- ROBLOX FIXME: require correct module when available
	local introspectionFromSchema = function()
	end -- require(utilitiesWorkspace.introspectionFromSchema).introspectionFromSchema

	-- ROBLOX deviation: utils
	local Array = require(srcWorkspace.luaUtils.Array)
	local NULL = require(srcWorkspace.luaUtils.null)

	--[[*
	--  * This function does a full cycle of going from a string with the contents of
	--  * the SDL, build in-memory GraphQLSchema from it, produce a client-side
	--  * representation of the schema by using "buildClientSchema" and then
	--  * returns that schema printed as SDL.
	--  *]]
	local function cycleIntrospection(expect_, sdlString)
		local serverSchema = buildSchema(sdlString)
		local initialIntrospection = introspectionFromSchema(serverSchema)
		local clientSchema = buildClientSchema(initialIntrospection)
		local secondIntrospection = introspectionFromSchema(clientSchema)

		--[[*
		-- * If the client then runs the introspection query against the client-side
		-- * schema, it should get a result identical to what was returned by the server
		-- *]]
		expect_(secondIntrospection).toEqual(initialIntrospection)

		return printSchema(clientSchema)
	end

	describe("Type System: build schema from introspection", function()
		itSKIP("builds a simple schema", function()
			local sdl = dedent(([[

      """Simple schema"""
      schema {
        query: Simple
      }

      """This is a simple type"""
      type Simple {
        """This is a string field"""
        string: String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		it("builds a schema without the query type", function()
			local sdl = dedent(([[

      type Query {
        foo: String
      }
    ]]):format())

	  		-- ROBLOX FIXME: use the real functions when introspectionFromSchema is available
			-- local schema = buildSchema(sdl)
			-- local introspection = introspectionFromSchema(schema)
			local introspection = require(script.Parent["buildClientSchema.roblox.introspection"]) -- introspectionFromSchema(schema)

			introspection.__schema.queryType = nil

			local clientSchema = buildClientSchema(introspection)
			expect(clientSchema:getQueryType()).to.equal(NULL)
			expect(printSchema(clientSchema)).to.equal(sdl)
		end)

		itSKIP("builds a simple schema with all operation types", function()
			local sdl = dedent(([[

      schema {
        query: QueryType
        mutation: MutationType
        subscription: SubscriptionType
      }

      """This is a simple mutation type"""
      type MutationType {
        """Set the string field"""
        string: String
      }

      """This is a simple query type"""
      type QueryType {
        """This is a string field"""
        string: String
      }

      """This is a simple subscription type"""
      type SubscriptionType {
        """This is a string field"""
        string: String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		it("uses built-in scalars when possible", function()
			local sdl = dedent(([[

      scalar CustomScalar

      type Query {
        int: Int
        float: Float
        string: String
        boolean: Boolean
        id: ID
        custom: CustomScalar
      }
    ]]):format())

	  		-- ROBLOX FIXME: uncomment when introspectionFromSchema is available
			-- expect(cycleIntrospection(expect, sdl)).to.equal(sdl)

			local schema = buildSchema(sdl)
	  		-- ROBLOX FIXME: use the real functions when introspectionFromSchema is available
			-- local introspection = introspectionFromSchema(schema)
			local introspection = require(script.Parent["buildClientSchema.roblox.introspection2"])
			local clientSchema = buildClientSchema(introspection)

			-- Built-ins are used
			expect(clientSchema:getType("Int")).to.equal(GraphQLInt)
			expect(clientSchema:getType("Float")).to.equal(GraphQLFloat)
			expect(clientSchema:getType("String")).to.equal(GraphQLString)
			expect(clientSchema:getType("Boolean")).to.equal(GraphQLBoolean)
			expect(clientSchema:getType("ID")).to.equal(GraphQLID)

			-- Custom are built
			local customScalar = schema:getType("CustomScalar")
			expect(clientSchema:getType("CustomScalar")).never.to.equal(customScalar)
		end)

		it("includes standard types only if they are used", function()
	  		-- ROBLOX FIXME: uncomment when introspectionFromSchema is available
	-- 		local schema = buildSchema(([[

    --   type Query {
    --     foo: String
    --   }
    -- ]]):format())
	  		-- ROBLOX FIXME: use the real functions when introspectionFromSchema is available
			-- local introspection = introspectionFromSchema(schema)
			local introspection = require(script.Parent["buildClientSchema.roblox.introspection3"])
			local clientSchema = buildClientSchema(introspection)

			expect(clientSchema:getType("Int")).to.equal(nil)
			expect(clientSchema:getType("Float")).to.equal(nil)
			expect(clientSchema:getType("ID")).to.equal(nil)
		end)

		itSKIP("builds a schema with a recursive type reference", function()
			local sdl = dedent(([[

      schema {
        query: Recur
      }

      type Recur {
        recur: Recur
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with a circular type reference", function()
			local sdl = dedent(([[

      type Dog {
        bestFriend: Human
      }

      type Human {
        bestFriend: Dog
      }

      type Query {
        dog: Dog
        human: Human
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with an interface", function()
			local sdl = dedent(([[

      type Dog implements Friendly {
        bestFriend: Friendly
      }

      interface Friendly {
        """The best friend of this friendly thing"""
        bestFriend: Friendly
      }

      type Human implements Friendly {
        bestFriend: Friendly
      }

      type Query {
        friendly: Friendly
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with an interface hierarchy", function()
			local sdl = dedent(([[

      type Dog implements Friendly & Named {
        bestFriend: Friendly
        name: String
      }

      interface Friendly implements Named {
        """The best friend of this friendly thing"""
        bestFriend: Friendly
        name: String
      }

      type Human implements Friendly & Named {
        bestFriend: Friendly
        name: String
      }

      interface Named {
        name: String
      }

      type Query {
        friendly: Friendly
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with an implicit interface", function()
			local sdl = dedent(([[

      type Dog implements Friendly {
        bestFriend: Friendly
      }

      interface Friendly {
        """The best friend of this friendly thing"""
        bestFriend: Friendly
      }

      type Query {
        dog: Dog
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with a union", function()
			local sdl = dedent(([[

      type Dog {
        bestFriend: Friendly
      }

      union Friendly = Dog | Human

      type Human {
        bestFriend: Friendly
      }

      type Query {
        friendly: Friendly
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with complex field values", function()
			local sdl = dedent(([[

      type Query {
        string: String
        listOfString: [String]
        nonNullString: String!
        nonNullListOfString: [String]!
        nonNullListOfNonNullString: [String!]!
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with field arguments", function()
			local sdl = dedent(([[

      type Query {
        """A field with a single arg"""
        one(
          """This is an int arg"""
          intArg: Int
        ): String

        """A field with a two args"""
        two(
          """This is an list of int arg"""
          listArg: [Int]

          """This is a required arg"""
          requiredArg: Boolean!
        ): String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with default value on custom scalar field", function()
			local sdl = dedent(([[

      scalar CustomScalar

      type Query {
        testField(testArg: CustomScalar = "default"): String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with an enum", function()
			local foodEnum = GraphQLEnumType({
				name = "Food",
				description = "Varieties of food stuffs",
				values = {
					VEGETABLES = {
						description = "Foods that are vegetables.",
						value = 1,
					},
					FRUITS = { value = 2 },
					OILS = {
						value = 3,
						deprecationReason = "Too fatty",
					},
				},
			})
			local schema = GraphQLSchema({
				query = GraphQLObjectType({
					name = "EnumFields",
					fields = {
						food = {
							description = "Repeats the arg you give it",
							type = foodEnum,
							args = {
								kind = {
									description = "what kind of food?",
									type = foodEnum,
								},
							},
						},
					},
				}),
			})

			local introspection = introspectionFromSchema(schema)
			local clientSchema = buildClientSchema(introspection)

			local secondIntrospection = introspectionFromSchema(clientSchema)
			expect(secondIntrospection).toEqual(introspection)

			-- It's also an Enum type on the client.
			local clientFoodEnum = assertEnumType(clientSchema:getType("Food"))

			-- Client types do not get server-only values, so `value` mirrors `name`,
			-- rather than using the integers defined in the "server" schema.
			expect(clientFoodEnum:getValues()).toEqual({
				{
					name = "VEGETABLES",
					description = "Foods that are vegetables.",
					value = "VEGETABLES",
					deprecationReason = nil,
					extensions = nil,
					astNode = nil,
				},
				{
					name = "FRUITS",
					description = nil,
					value = "FRUITS",
					deprecationReason = nil,
					extensions = nil,
					astNode = nil,
				},
				{
					name = "OILS",
					description = nil,
					value = "OILS",
					deprecationReason = "Too fatty",
					extensions = nil,
					astNode = nil,
				},
			})
		end)

		itSKIP("builds a schema with an input object", function()
			local sdl = dedent(([[

      """An input address"""
      input Address {
        """What street is this address?"""
        street: String!

        """The city the address is within?"""
        city: String!

        """The country (blank will assume USA)."""
        country: String = "USA"
      }

      type Query {
        """Get a geocode from an address"""
        geocode(
          """The address to lookup"""
          address: Address
        ): String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with field arguments with default values", function()
			local sdl = dedent(([[

      input Geo {
        lat: Float
        lon: Float
      }

      type Query {
        defaultInt(intArg: Int = 30): String
        defaultList(listArg: [Int] = [1, 2, 3]): String
        defaultObject(objArg: Geo = {lat: 37.485, lon: -122.148}): String
        defaultNull(intArg: Int = null): String
        noDefault(intArg: Int): String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with custom directives", function()
			local sdl = dedent(([[

      """This is a custom directive"""
      directive @customDirective repeatable on FIELD

      type Query {
        string: String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema without directives", function()
			local sdl = dedent(([[

      type Query {
        string: String
      }
    ]]):format())

			local schema = buildSchema(sdl)
			local introspection = introspectionFromSchema(schema)

			introspection.__schema.directives = nil

			local clientSchema = buildClientSchema(introspection)

			expect(schema:getDirectives()).to.have.lengthOf.above(0)
			expect(clientSchema:getDirectives()).toEqual({})
			expect(printSchema(clientSchema)).to.equal(sdl)
		end)

		itSKIP("builds a schema aware of deprecation", function()
			local sdl = dedent(([[

      directive @someDirective(
        """This is a shiny new argument"""
        shinyArg: SomeInputObject

        """This was our design mistake :("""
        oldArg: String @deprecated(reason: "Use shinyArg")
      ) on QUERY

      enum Color {
        """So rosy"""
        RED

        """So grassy"""
        GREEN

        """So calming"""
        BLUE

        """So sickening"""
        MAUVE @deprecated(reason: "No longer in fashion")
      }

      input SomeInputObject {
        """Nothing special about it, just deprecated for some unknown reason"""
        oldField: String @deprecated(reason: "Don't use it, use newField instead!")

        """Same field but with a new name"""
        newField: String
      }

      type Query {
        """This is a shiny string field"""
        shinyString: String

        """This is a deprecated string field"""
        deprecatedString: String @deprecated(reason: "Use shinyString")

        """Color of a week"""
        color: Color

        """Some random field"""
        someField(
          """This is a shiny new argument"""
          shinyArg: SomeInputObject

          """This was our design mistake :("""
          oldArg: String @deprecated(reason: "Use shinyArg")
        ): String
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with empty deprecation reasons", function()
			local sdl = dedent(([[

      directive @someDirective(someArg: SomeInputObject @deprecated(reason: "")) on QUERY

      type Query {
        someField(someArg: SomeInputObject @deprecated(reason: "")): SomeEnum @deprecated(reason: "")
      }

      input SomeInputObject {
        someInputField: String @deprecated(reason: "")
      }

      enum SomeEnum {
        SOME_VALUE @deprecated(reason: "")
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("builds a schema with specifiedBy url", function()
			local sdl = dedent(([[

      scalar Foo @specifiedBy(url: "https://example.com/foo_spec")

      type Query {
        foo: Foo
      }
    ]]):format())

			expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
		end)

		itSKIP("can use client schema for limited execution", function()
			local schema = buildSchema(([[

      scalar CustomScalar

      type Query {
        foo(custom1: CustomScalar, custom2: CustomScalar): String
      }
    ]]):format())

			local introspection = introspectionFromSchema(schema)
			local clientSchema = buildClientSchema(introspection)

			local result = graphqlSync({
				schema = clientSchema,
				source = "query Limited($v: CustomScalar) { foo(custom1: 123, custom2: $v) }",
				rootValue = {
					foo = "bar",
					unused = "value",
				},
				variableValues = {
					v = "baz",
				},
			})

			expect(result.data).toEqual({
				foo = "bar",
			})
		end)

		describe("can build invalid schema", function()
			-- ROBLOX FIXME: uncomment when available
			-- local schema = buildSchema('type Query', {assumeValid = true})
			-- local introspection = introspectionFromSchema(schema)
			-- local clientSchema = buildClientSchema(introspection, {assumeValid = true})

			-- expect(clientSchema:toConfig().assumeValid).to.equal(true)
		end)

		describe("throws when given invalid introspection", function()
			local dummySchema = buildSchema(([[

      type Query {
        foo(bar: String): String
      }

      interface SomeInterface {
        foo: String
      }

      union SomeUnion = Query

      enum SomeEnum { FOO }

      input SomeInputObject {
        foo: String
      }

      directive @SomeDirective on QUERY
    ]]):format())

			itSKIP("throws when introspection is missing __schema property", function()
				-- $FlowExpectedError[incompatible-call]
				expect(function()
					return buildClientSchema(nil)
				end).to.throw("Invalid or incomplete introspection result. Ensure that you are passing \"data\" property of introspection response and no \"errors\" was returned alongside: null.")

				-- $FlowExpectedError[prop-missing]
				expect(function()
					return buildClientSchema({})
				end).to.throw("Invalid or incomplete introspection result. Ensure that you are passing \"data\" property of introspection response and no \"errors\" was returned alongside: {}.")
			end)

			itSKIP("throws when referenced unknown type", function()
				local introspection = introspectionFromSchema(dummySchema)

				introspection.__schema.types = Array.filter(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name ~= "Query"
				end)

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Invalid or incomplete schema, unknown type: Query. Ensure that a full introspection query is used in order to build a client schema.")
			end)

			itSKIP("throws when missing definition for one of the standard scalars", function()
				local schema = buildSchema(([[

        type Query {
          foo: Float
        }
      ]]):format())
				local introspection = introspectionFromSchema(schema)

				introspection.__schema.types = Array.filter(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name ~= "Float"
				end)

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Invalid or incomplete schema, unknown type: Float. Ensure that a full introspection query is used in order to build a client schema.")
			end)

			itSKIP("throws when type reference is missing name", function()
				local introspection = introspectionFromSchema(dummySchema)

				expect(introspection).to.have.nested.property("__schema.queryType.name")

				introspection.__schema.queryType.name = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Unknown type reference: {}.")
			end)

			itSKIP("throws when missing kind", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.property("kind")

				queryTypeIntrospection.kind = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Invalid or incomplete introspection result. Ensure that a full introspection query is used in order to build a client schema: { name: "Query", .* }\./,
				)
			end)

			itSKIP("throws when missing interfaces", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.property("interfaces")

				queryTypeIntrospection.interfaces = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing interfaces: { kind: "OBJECT", name: "Query", .* }\./,
				)
			end)

			itSKIP("Legacy support for interfaces with null as interfaces field", function()
				local introspection = introspectionFromSchema(dummySchema)
				local someInterfaceIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "SomeInterface"
				end)

				expect(someInterfaceIntrospection).to.have.property("interfaces")
				someInterfaceIntrospection.interfaces = nil

				local clientSchema = buildClientSchema(introspection)
				expect(printSchema(clientSchema)).to.equal(printSchema(dummySchema))
			end)

			itSKIP("throws when missing fields", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.property("fields")
				queryTypeIntrospection.fields = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing fields: { kind: "OBJECT", name: "Query", .* }\./,
				)
			end)

			itSKIP("throws when missing field args", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.nested.property("fields[1].args")
				queryTypeIntrospection.fields[1].args = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing field args: { name: "foo", .* }\./,
				)
			end)

			itSKIP("throws when output type is used as an arg type", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.nested.property("fields[1].args[1].type.name", "String")
				queryTypeIntrospection.fields[1].args[1].type.name = "SomeUnion"

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Introspection must provide input type for arguments, but received: SomeUnion.")
			end)

			itSKIP("throws when input type is used as a field type", function()
				local introspection = introspectionFromSchema(dummySchema)
				local queryTypeIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "Query"
				end)

				expect(queryTypeIntrospection).to.have.nested.property("fields[1].type.name", "String")
				queryTypeIntrospection.fields[1].type.name = "SomeInputObject"

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Introspection must provide output type for fields, but received: SomeInputObject.")
			end)

			itSKIP("throws when missing possibleTypes", function()
				local introspection = introspectionFromSchema(dummySchema)
				local someUnionIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "SomeUnion"
				end)

				expect(someUnionIntrospection).to.have.property("possibleTypes")
				someUnionIntrospection.possibleTypes = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing possibleTypes: { kind: "UNION", name: "SomeUnion",.* }\./,
				)
			end)

			itSKIP("throws when missing enumValues", function()
				local introspection = introspectionFromSchema(dummySchema)
				local someEnumIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "SomeEnum"
				end)

				expect(someEnumIntrospection).to.have.property("enumValues")
				someEnumIntrospection.enumValues = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing enumValues: { kind: "ENUM", name: "SomeEnum", .* }\./,
				)
			end)

			itSKIP("throws when missing inputFields", function()
				local introspection = introspectionFromSchema(dummySchema)
				local someInputObjectIntrospection = Array.find(introspection.__schema.types, function(_ref)
					local name = _ref.name
					return name == "SomeInputObject"
				end)

				expect(someInputObjectIntrospection).to.have.property("inputFields")
				someInputObjectIntrospection.inputFields = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing inputFields: { kind: "INPUT_OBJECT", name: "SomeInputObject", .* }\./,
				)
			end)

			itSKIP("throws when missing directive locations", function()
				local introspection = introspectionFromSchema(dummySchema)

				local someDirectiveIntrospection = introspection.__schema.directives[1]
				expect(someDirectiveIntrospection).to.deep.include({
					name = "SomeDirective",
					locations = {
						"QUERY",
					},
				})
				someDirectiveIntrospection.locations = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing directive locations: { name: "SomeDirective", .* }\./,
				)
			end)

			itSKIP("throws when missing directive args", function()
				local introspection = introspectionFromSchema(dummySchema)

				local someDirectiveIntrospection = introspection.__schema.directives[1]
				expect(someDirectiveIntrospection).to.deep.include({
					name = "SomeDirective",
					args = {},
				})
				someDirectiveIntrospection.args = nil

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw(
				-- ROBLOX FIXME: no regex in Lua - try using .toThrow matcher
				-- /Introspection result missing directive args: { name: "SomeDirective", .* }\./,
				)
			end)
		end)

		describe("very deep decorators are not supported", function()
			itSKIP("fails on very deep (> 7 levels) lists", function()
				local schema = buildSchema(([=[

        type Query {
          foo: [[[[[[[[String]]]]]]]]
        }
      ]=]):format())

				local introspection = introspectionFromSchema(schema)
				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Decorated type deeper than introspection query.")
			end)

			itSKIP("fails on a very deep (> 7 levels) non-null", function()
				local schema = buildSchema(([[

        type Query {
          foo: [[[[String!]!]!]!]
        }
      ]]):format())

				local introspection = introspectionFromSchema(schema)
				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Decorated type deeper than introspection query.")
			end)

			itSKIP("succeeds on deep (<= 7 levels) types", function()
				-- e.g., fully non-null 3D matrix
				local sdl = dedent(([[

        type Query {
          foo: [[[String!]!]!]!
        }
      ]]):format())

				expect(cycleIntrospection(expect, sdl)).to.equal(sdl)
			end)
		end)

		describe("prevents infinite recursion on invalid introspection", function()
			itSKIP("recursive interfaces", function()
				local sdl = ([[

        type Query {
          foo: Foo
        }

        type Foo implements Foo {
          foo: String
        }
      ]]):format()
				local schema = buildSchema(sdl, { assumeValid = true })
				local introspection = introspectionFromSchema(schema)

				local fooIntrospection = Array.find(introspection.__schema.types, function(type_)
					return type_.name == "Foo"
				end)
				expect(fooIntrospection).to.deep.include({
					name = "Foo",
					interfaces = {
						{
							kind = "OBJECT",
							name = "Foo",
							ofType = nil,
						},
					},
				})

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Expected Foo to be a GraphQL Interface type.")
			end)

			itSKIP("recursive union", function()
				local sdl = ([[

        type Query {
          foo: Foo
        }

        union Foo = Foo
      ]]):format()
				local schema = buildSchema(sdl, { assumeValid = true })
				local introspection = introspectionFromSchema(schema)

				local fooIntrospection = Array.find(introspection.__schema.types, function(type_)
					return type_.name == "Foo"
				end)
				expect(fooIntrospection).to.deep.include({
					name = "Foo",
					possibleTypes = {
						{
							kind = "UNION",
							name = "Foo",
							ofType = nil,
						},
					},
				})

				expect(function()
					return buildClientSchema(introspection)
				end).to.throw("Expected Foo to be a GraphQL Object type.")
			end)
		end)
	end)
end
