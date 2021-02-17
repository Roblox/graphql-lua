-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/__tests__/buildASTSchema-test.js

return function()
	local utilitiesWorkspace = script.Parent.Parent
	local srcWorkspace = utilitiesWorkspace.Parent

	local dedent = require(srcWorkspace.__testUtils__.dedent).dedent

	local invariant = require(srcWorkspace.jsutils.invariant).invariant

	local Kind = require(srcWorkspace.language.kinds).Kind
	local parse = require(srcWorkspace.language.parser).parse
	local print_ = require(srcWorkspace.language.printer).print

	local GraphQLSchema = require(srcWorkspace.type.schema).GraphQLSchema
	local validateSchema: any = {} -- require(srcWorkspace.type.validate).validateSchema
	local introspectionImport = require(srcWorkspace.type.introspection)
	local __Schema = introspectionImport.__Schema
	local __EnumValue = introspectionImport.__EnumValue
	local directivesImport = require(srcWorkspace.type.directives)
	local assertDirective = directivesImport.assertDirective
	local GraphQLSkipDirective = directivesImport.GraphQLSkipDirective
	local GraphQLIncludeDirective = directivesImport.GraphQLIncludeDirective
	local GraphQLDeprecatedDirective = directivesImport.GraphQLDeprecatedDirective
	local GraphQLSpecifiedByDirective = directivesImport.GraphQLSpecifiedByDirective
	local scalarsImport = require(srcWorkspace.type.scalars)
	local GraphQLID = scalarsImport.GraphQLID
	local GraphQLInt = scalarsImport.GraphQLInt
	local GraphQLFloat = scalarsImport.GraphQLFloat
	local GraphQLString = scalarsImport.GraphQLString
	local GraphQLBoolean = scalarsImport.GraphQLBoolean
	local definitionImport = require(srcWorkspace.type.definition)
	local assertObjectType = definitionImport.assertObjectType
	local assertInputObjectType = definitionImport.assertInputObjectType
	local assertEnumType = definitionImport.assertEnumType
	local assertUnionType = definitionImport.assertUnionType
	local assertInterfaceType = definitionImport.assertInterfaceType
	local assertScalarType = definitionImport.assertScalarType

	-- ROBLOX FIXME: use actual module when available
	local graphqlSync = {} -- require(srcWorkspace.graphql).graphqlSync

	local printSchemaImport = require(utilitiesWorkspace.printSchema)
	local printType = printSchemaImport.printType
	local printSchema = printSchemaImport.printSchema
	local buildASTSchemaImport = require(utilitiesWorkspace.buildASTSchema)
	local buildASTSchema = buildASTSchemaImport.buildASTSchema
	local buildSchema = buildASTSchemaImport.buildSchema

	local UtilArray = require(srcWorkspace.luaUtils.Array)
	local Object = require(srcWorkspace.Parent.Packages.LuauPolyfill).Object

	--[[*
	--  * This function does a full cycle of going from a string with the contents of
	--  * the SDL, parsed in a schema AST, materializing that schema AST into an
	--  * in-memory GraphQLSchema, and then finally printing that object into the SDL
	--  *]]
	local function cycleSDL(sdl: string): string
		return printSchema(buildSchema(sdl))
	end

	local function printASTNode(obj): string
		invariant((function()
			return obj.astNode
		end)() ~= nil)

		return print_(obj.astNode)
	end

	local function printAllASTNodes(obj): string
		invariant(obj.astNode ~= nil and obj.extensionASTNodes ~= nil)

		return print_({
			kind = Kind.DOCUMENT,
			definitions = UtilArray.concat({ obj.astNode }, obj.extensionASTNodes),
		})
	end

	describe("Schema Builder", function()
		itSKIP("can use built schema for limited execution", function()
			local schema = buildASTSchema(parse([[

        type Query {
          str: String
        }
      ]]))

			local result = graphqlSync({
				schema = schema,
				source = "{ str }",
				rootValue = { str = 123 },
			})
			expect(result.data).toEqual({
				str = "123",
			})
		end)

		itSKIP("can build a schema directly from the source", function()
			local schema = buildSchema([[

      type Query {
        add(x: Int, y: Int): Int
      }
    ]])

			local source = "{ add(x: 34, y: 55) }"
			local rootValue = {
				add = function(_ref)
					local x, y = _ref.x, _ref.y

					return x + y
				end,
			}
			expect(graphqlSync({
				schema = schema,
				source = source,
				rootValue = rootValue,
			})).toEqual({
				data = { add = 89 },
			})
		end)

		it("Ignores non-type system definitions", function()
			local sdl = [[

      type Query {
        str: String
      }

      fragment SomeFragment on Query {
        str
      }
    ]]
			expect(function()
				return buildSchema(sdl)
			end).never.toThrow()
		end)

		it("Match order of default types and directives", function()
			local schema = GraphQLSchema.new({})
			local sdlSchema = buildASTSchema({
				kind = Kind.DOCUMENT,
				definitions = {},
			})

			expect(sdlSchema:getDirectives()).toEqual(schema:getDirectives())

			expect(sdlSchema:getTypeMap()).toEqual(schema:getTypeMap())
			expect(Object.keys(sdlSchema:getTypeMap())).toEqual(Object.keys(schema:getTypeMap()))
		end)

		it("Empty type", function()
			local sdl = dedent([[

      type EmptyType
    ]])
			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple type", function()
			local sdl = dedent([[

      type Query {
        str: String
        int: Int
        float: Float
        id: ID
        bool: Boolean
      }
    ]])
	  		-- ROBLOX FIXME: uncomment when printSchema is available
			-- expect(cycleSDL(sdl)).to.equal(sdl)

			local schema = buildSchema(sdl)
			-- Built-ins are used
			expect(schema:getType("Int")).to.equal(GraphQLInt)
			expect(schema:getType("Float")).to.equal(GraphQLFloat)
			expect(schema:getType("String")).to.equal(GraphQLString)
			expect(schema:getType("Boolean")).to.equal(GraphQLBoolean)
			expect(schema:getType("ID")).to.equal(GraphQLID)
		end)

		it("include standard type only if it is used", function()
			local schema = buildSchema("type Query")

			-- String and Boolean are always included through introspection types
			expect(schema:getType("Int")).to.equal(nil)
			expect(schema:getType("Float")).to.equal(nil)
			expect(schema:getType("ID")).to.equal(nil)
		end)

		it("With directives", function()
			local sdl = dedent([[

      directive @foo(arg: Int) on FIELD

      directive @repeatableFoo(arg: Int) repeatable on FIELD
    ]])
			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Supports descriptions", function()
			local sdl = dedent([[

      """Do you agree that this is the most creative schema ever?"""
      schema {
        query: Query
      }

      """This is a directive"""
      directive @foo(
        """It has an argument"""
        arg: Int
      ) on FIELD

      """Who knows what inside this scalar?"""
      scalar MysteryScalar

      """This is a input object type"""
      input FooInput {
        """It has a field"""
        field: Int
      }

      """This is a interface type"""
      interface Energy {
        """It also has a field"""
        str: String
      }

      """There is nothing inside!"""
      union BlackHole

      """With an enum"""
      enum Color {
        RED

        """Not a creative color"""
        GREEN
        BLUE
      }

      """What a great type"""
      type Query {
        """And a field to boot"""
        str: String
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      """Do you agree that this is the most creative schema ever?"""
      schema {
        query: Query
      }

      """This is a directive"""
      directive @foo(
        """It has an argument"""
        arg: Int
      ) on FIELD

      """With an enum"""
      enum Color {
        RED
        BLUE

        """Not a creative color"""
        GREEN
      }

      """There is nothing inside!"""
      union BlackHole

      """What a great type"""
      type Query {
        """And a field to boot"""
        str: String
      }

      """This is a input object type"""
      input FooInput {
        """It has a field"""
        field: Int
      }

      """This is a interface type"""
      interface Energy {
        """It also has a field"""
        str: String
      }

      """Who knows what inside this scalar?"""
      scalar MysteryScalar
    ]]))
		end)

		it("Maintains @include, @skip & @specifiedBy", function()
			local schema = buildSchema("type Query")

			expect(#schema:getDirectives()).to.equal(4)
			expect(schema:getDirective("skip")).to.equal(GraphQLSkipDirective)
			expect(schema:getDirective("include")).to.equal(GraphQLIncludeDirective)
			expect(schema:getDirective("deprecated")).to.equal(GraphQLDeprecatedDirective)
			expect(schema:getDirective("specifiedBy")).to.equal(GraphQLSpecifiedByDirective)
		end)

		it("Overriding directives excludes specified", function()
			local schema = buildSchema([[

      directive @skip on FIELD
      directive @include on FIELD
      directive @deprecated on FIELD_DEFINITION
      directive @specifiedBy on FIELD_DEFINITION
    ]])

			expect(#schema:getDirectives()).to.equal(4)
			expect(schema:getDirective("skip")).never.to.equal(GraphQLSkipDirective)
			expect(schema:getDirective("include")).never.to.equal(GraphQLIncludeDirective)
			expect(schema:getDirective("deprecated")).never.to.equal(GraphQLDeprecatedDirective)
			expect(schema:getDirective("specifiedBy")).never.to.equal(GraphQLSpecifiedByDirective)
		end)

		it("Adding directives maintains @include, @skip & @specifiedBy", function()
			local schema = buildSchema([[

      directive @foo(arg: Int) on FIELD
    ]])

			expect(#schema:getDirectives()).to.equal(5)
			expect(schema:getDirective("skip")).never.to.equal(nil)
			expect(schema:getDirective("include")).never.to.equal(nil)
			expect(schema:getDirective("deprecated")).never.to.equal(nil)
			expect(schema:getDirective("specifiedBy")).never.to.equal(nil)
		end)

		it("Type modifiers", function()
			local sdl = dedent([[

      type Query {
        nonNullStr: String!
        listOfStrings: [String]
        listOfNonNullStrings: [String!]
        nonNullListOfStrings: [String]!
        nonNullListOfNonNullStrings: [String!]!
      }
    ]])

			--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      type Query {
        listOfStrings: [String]
        nonNullStr: String!
        nonNullListOfNonNullStrings: [String!]!
        listOfNonNullStrings: [String!]
        nonNullListOfStrings: [String]!
      }
    ]]))
		end)

		it("Recursive type", function()
			local sdl = dedent([[

      type Query {
        str: String
        recurse: Query
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Two types circular", function()
			local sdl = dedent([[

      type TypeOne {
        str: String
        typeTwo: TypeTwo
      }

      type TypeTwo {
        str: String
        typeOne: TypeOne
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Single argument field", function()
			local sdl = dedent([[

      type Query {
        str(int: Int): String
        floatToStr(float: Float): String
        idToStr(id: ID): String
        booleanToStr(bool: Boolean): String
        strToStr(bool: String): String
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      type Query {
        str(int: Int): String
        idToStr(id: ID): String
        floatToStr(float: Float): String
        booleanToStr(bool: Boolean): String
        strToStr(bool: String): String
      }
    ]]))
		end)

		it("Simple type with multiple arguments", function()
			local sdl = dedent([[

      type Query {
        str(int: Int, bool: Boolean): String
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Empty interface", function()
			local sdl = dedent([[

      interface EmptyInterface
    ]])
			local parsed = parse(sdl)
			local definition = parsed.definitions[1]

			expect(definition.kind == "InterfaceTypeDefinition" and definition.interfaces).toEqual({}, "The interfaces property must be an empty array.")
			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple type with interface", function()
			local sdl = dedent([[

      type Query implements WorldInterface {
        str: String
      }

      interface WorldInterface {
        str: String
      }
    ]])

			--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      interface WorldInterface {
        str: String
      }

      type Query implements WorldInterface {
        str: String
      }
    ]]))
		end)

		it("Simple interface hierarchy", function()
			local sdl = dedent([[

      schema {
        query: Child
      }

      interface Child implements Parent {
        str: String
      }

      type Hello implements Parent & Child {
        str: String
      }

      interface Parent {
        str: String
      }
    ]])

			--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      schema {
        query: Child
      }

      interface Parent {
        str: String
      }

      interface Child implements Parent {
        str: String
      }

      type Hello implements Parent & Child {
        str: String
      }
    ]]))
		end)

		it("Empty enum", function()
			local sdl = dedent([[

      enum EmptyEnum
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple output enum", function()
			local sdl = dedent([[

      enum Hello {
        WORLD
      }

      type Query {
        hello: Hello
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple input enum", function()
			local sdl = dedent([[

      enum Hello {
        WORLD
      }

      type Query {
        str(hello: Hello): String
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Multiple value enum", function()
			local sdl = dedent([[

      enum Hello {
        WO
        RLD
      }

      type Query {
        hello: Hello
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      enum Hello {
        RLD
        WO
      }

      type Query {
        hello: Hello
      }
    ]]))
		end)

		it("Empty union", function()
			local sdl = dedent([[

      union EmptyUnion
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple Union", function()
			local sdl = dedent([[

      union Hello = World

      type Query {
        hello: Hello
      }

      type World {
        str: String
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Multiple Union", function()
			local sdl = dedent([[

      union Hello = WorldOne | WorldTwo

      type Query {
        hello: Hello
      }

      type WorldOne {
        str: String
      }

      type WorldTwo {
        str: String
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      union Hello = WorldOne | WorldTwo

      type WorldOne {
        str: String
      }

      type Query {
        hello: Hello
      }

      type WorldTwo {
        str: String
      }
    ]]))
		end)

		itSKIP("Can build recursive Union", function()
			local schema = buildSchema([[

      union Hello = Hello

      type Query {
        hello: Hello
      }
    ]])
			local errors = validateSchema(schema)

			expect(#errors > 0).to.equal(true)
		end)

		it("Custom Scalar", function()
			local sdl = dedent([[

      scalar CustomScalar

      type Query {
        customScalar: CustomScalar
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Empty Input Object", function()
			local sdl = dedent([[

      input EmptyInputObject
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple Input Object", function()
			local sdl = dedent([[

      input Input {
        int: Int
      }

      type Query {
        field(in: Input): String
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      type Query {
        field(in: Input): String
      }

      input Input {
        int: Int
      }
    ]]))
		end)

		it("Simple argument field with default", function()
			local sdl = dedent([[

      type Query {
        str(int: Int = 2): String
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Custom scalar argument field with default", function()
			local sdl = dedent([[

      scalar CustomScalar

      type Query {
        str(int: CustomScalar = 2): String
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple type with mutation", function()
			local sdl = dedent([[

      schema {
        query: HelloScalars
        mutation: Mutation
      }

      type HelloScalars {
        str: String
        int: Int
        bool: Boolean
      }

      type Mutation {
        addHelloScalars(str: String, int: Int, bool: Boolean): HelloScalars
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Simple type with subscription", function()
			local sdl = dedent([[

      schema {
        query: HelloScalars
        subscription: Subscription
      }

      type HelloScalars {
        str: String
        int: Int
        bool: Boolean
      }

      type Subscription {
        subscribeHelloScalars(str: String, int: Int, bool: Boolean): HelloScalars
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      schema {
        query: HelloScalars
        subscription: Subscription
      }

      type Subscription {
        subscribeHelloScalars(str: String, int: Int, bool: Boolean): HelloScalars
      }

      type HelloScalars {
        str: String
        int: Int
        bool: Boolean
      }
    ]]))
		end)

		it("Unreferenced type implementing referenced interface", function()
			local sdl = dedent([[

      type Concrete implements Interface {
        key: String
      }

      interface Interface {
        key: String
      }

      type Query {
        interface: Interface
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      type Query {
        interface: Interface
      }

      type Concrete implements Interface {
        key: String
      }

      interface Interface {
        key: String
      }
    ]]))
		end)

		it("Unreferenced interface implementing referenced interface", function()
			local sdl = dedent([[

      interface Child implements Parent {
        key: String
      }

      interface Parent {
        key: String
      }

      type Query {
        interfaceField: Parent
      }
    ]])

			expect(cycleSDL(sdl)).to.equal(sdl)
		end)

		it("Unreferenced type implementing referenced union", function()
			local sdl = dedent([[

      type Concrete {
        key: String
      }

      type Query {
        union: Union
      }

      union Union = Concrete
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      union Union = Concrete

      type Query {
        union: Union
      }

      type Concrete {
        key: String
      }
    ]]))
		end)

		it("Supports @deprecated", function()
			local sdl = dedent([[

      enum MyEnum {
        VALUE
        OLD_VALUE @deprecated
        OTHER_VALUE @deprecated(reason: "Terrible reasons")
      }

      input MyInput {
        oldInput: String @deprecated
        otherInput: String @deprecated(reason: "Use newInput")
        newInput: String
      }

      type Query {
        field1: String @deprecated
        field2: Int @deprecated(reason: "Because I said so")
        enum: MyEnum
        field3(oldArg: String @deprecated, arg: String): String
        field4(oldArg: String @deprecated(reason: "Why not?"), arg: String): String
        field5(arg: MyInput): String
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      enum MyEnum {
        OTHER_VALUE @deprecated(reason: "Terrible reasons")
        OLD_VALUE @deprecated
        VALUE
      }

      input MyInput {
        otherInput: String @deprecated(reason: "Use newInput")
        oldInput: String @deprecated
        newInput: String
      }

      type Query {
        field1: String @deprecated
        field2: Int @deprecated(reason: "Because I said so")
        enum: MyEnum
        field3(arg: String, oldArg: String @deprecated): String
        field5(arg: MyInput): String
        field4(arg: String, oldArg: String @deprecated(reason: "Why not?")): String
      }
    ]]))

			local schema = buildSchema(sdl)
			local myEnum = assertEnumType(schema:getType("MyEnum"))
			local value = myEnum:getValue("VALUE")

			expect(value).toObjectContain({ deprecationReason = nil })

			local oldValue = myEnum:getValue("OLD_VALUE")

			expect(oldValue).toObjectContain({
				deprecationReason = "No longer supported",
			})

			local otherValue = myEnum:getValue("OTHER_VALUE")

			expect(otherValue).toObjectContain({
				deprecationReason = "Terrible reasons",
			})

			local rootFields = assertObjectType(schema:getType("Query")):getFields()

			expect(rootFields.field1).toObjectContain({
				deprecationReason = "No longer supported",
			})
			expect(rootFields.field2).toObjectContain({
				deprecationReason = "Because I said so",
			})

			local inputFields = assertInputObjectType(schema:getType("MyInput")):getFields()
			local newInput = inputFields.newInput

			expect(newInput).toObjectContain({ deprecationReason = nil })

			local oldInput = inputFields.oldInput

			expect(oldInput).toObjectContain({
				deprecationReason = "No longer supported",
			})

			local otherInput = inputFields.otherInput

			expect(otherInput).toObjectContain({
				deprecationReason = "Use newInput",
			})

			--[[
			--  ROBLOX deviation: oldField is second rather than first
			--  I believe this is working in JS version because Object.entries iterates over properties in order they where added (at least in most browsers and node?)
			--  This is probably a small bug/issue in upstream as according to MDN developer should not depend on the order of entries execution
			-- 	ROBLOX FIXME: #142 https://github.com/Roblox/graphql-lua/issues/142
			--]]
			local field3OldArg = rootFields.field3.args[2]

			expect(field3OldArg).toObjectContain({
				deprecationReason = "No longer supported",
			})

			-- ROBLOX deviation: oldField is second rather than first
			-- ROBLOX FIXME: #142 https://github.com/Roblox/graphql-lua/issues/142
			local field4OldArg = rootFields.field4.args[2]

			expect(field4OldArg).toObjectContain({
				deprecationReason = "Why not?",
			})
		end)

		it("Supports @specifiedBy", function()
			local sdl = dedent([[

      scalar Foo @specifiedBy(url: "https://example.com/foo_spec")

      type Query {
        foo: Foo @deprecated
      }
    ]])

	  		--[[
				ROBLOX FIXME: ordering is not preserved
				original code: expect(cycleSDL(sdl)).to.equal(sdl)
			--]]
			expect(cycleSDL(sdl)).to.equal(dedent([[

      type Query {
        foo: Foo @deprecated
      }

      scalar Foo @specifiedBy(url: "https://example.com/foo_spec")
    ]]))

			local schema = buildSchema(sdl)

			expect(schema:getType("Foo")).toObjectContain({
				specifiedByUrl = "https://example.com/foo_spec",
			})
		end)

		it("Correctly extend scalar type", function()
			local scalarSDL = dedent([[

      scalar SomeScalar

      extend scalar SomeScalar @foo

      extend scalar SomeScalar @bar
    ]])
			local schema = buildSchema(([[

      %s
      directive @foo on SCALAR
      directive @bar on SCALAR
    ]]):format(scalarSDL))
			local someScalar = assertScalarType(schema:getType("SomeScalar"))

			expect(printType(someScalar) .. "\n").to.equal(dedent([[

      scalar SomeScalar
    ]]))
			expect(printAllASTNodes(someScalar)).to.equal(scalarSDL)
		end)

		it("Correctly extend object type", function()
			local objectSDL = dedent([[

      type SomeObject implements Foo {
        first: String
      }

      extend type SomeObject implements Bar {
        second: Int
      }

      extend type SomeObject implements Baz {
        third: Float
      }
    ]])
			local schema = buildSchema(([[

      %s
      interface Foo
      interface Bar
      interface Baz
    ]]):format(objectSDL))
			local someObject = assertObjectType(schema:getType("SomeObject"))

			expect(printType(someObject) .. "\n").to.equal(dedent([[

      type SomeObject implements Foo & Bar & Baz {
        first: String
        second: Int
        third: Float
      }
    ]]))
			expect(printAllASTNodes(someObject)).to.equal(objectSDL)
		end)

		it("Correctly extend interface type", function()
			local interfaceSDL = dedent([[

      interface SomeInterface {
        first: String
      }

      extend interface SomeInterface {
        second: Int
      }

      extend interface SomeInterface {
        third: Float
      }
    ]])
			local schema = buildSchema(interfaceSDL)
			local someInterface = assertInterfaceType(schema:getType("SomeInterface"))

			expect(printType(someInterface) .. "\n").to.equal(dedent([[

      interface SomeInterface {
        first: String
        second: Int
        third: Float
      }
    ]]))
			expect(printAllASTNodes(someInterface)).to.equal(interfaceSDL)
		end)

		it("Correctly extend union type", function()
			local unionSDL = dedent([[

      union SomeUnion = FirstType

      extend union SomeUnion = SecondType

      extend union SomeUnion = ThirdType
    ]])
			local schema = buildSchema(([[

      %s
      type FirstType
      type SecondType
      type ThirdType
    ]]):format(unionSDL))
			local someUnion = assertUnionType(schema:getType("SomeUnion"))

			expect(printType(someUnion) .. "\n").to.equal(dedent([[

      union SomeUnion = FirstType | SecondType | ThirdType
    ]]))
			expect(printAllASTNodes(someUnion)).to.equal(unionSDL)
		end)

		it("Correctly extend enum type", function()
			local enumSDL = dedent([[

      enum SomeEnum {
        FIRST
      }

      extend enum SomeEnum {
        SECOND
      }

      extend enum SomeEnum {
        THIRD
      }
    ]])
			local schema = buildSchema(enumSDL)
			local someEnum = assertEnumType(schema:getType("SomeEnum"))

			expect(printType(someEnum) .. "\n").to.equal(dedent([[

      enum SomeEnum {
        FIRST
        SECOND
        THIRD
      }
    ]]))
			expect(printAllASTNodes(someEnum)).to.equal(enumSDL)
		end)

		it("Correctly extend input object type", function()
			local inputSDL = dedent([[

      input SomeInput {
        first: String
      }

      extend input SomeInput {
        second: Int
      }

      extend input SomeInput {
        third: Float
      }
    ]])
			local schema = buildSchema(inputSDL)
			local someInput = assertInputObjectType(schema:getType("SomeInput"))

			expect(printType(someInput) .. "\n").to.equal(dedent([[

      input SomeInput {
        first: String
        second: Int
        third: Float
      }
    ]]))
			expect(printAllASTNodes(someInput)).to.equal(inputSDL)
		end)

		it("Correctly assign AST nodes", function()
			local sdl = dedent([[

      schema {
        query: Query
      }

      type Query {
        testField(testArg: TestInput): TestUnion
      }

      input TestInput {
        testInputField: TestEnum
      }

      enum TestEnum {
        TEST_VALUE
      }

      union TestUnion = TestType

      interface TestInterface {
        interfaceField: String
      }

      type TestType implements TestInterface {
        interfaceField: String
      }

      scalar TestScalar

      directive @test(arg: TestScalar) on FIELD
    ]])
			local ast = parse(sdl, { noLocation = true })
			local schema = buildASTSchema(ast)
			local query = assertObjectType(schema:getType("Query"))
			local testInput = assertInputObjectType(schema:getType("TestInput"))
			local testEnum = assertEnumType(schema:getType("TestEnum"))
			local testUnion = assertUnionType(schema:getType("TestUnion"))
			local testInterface = assertInterfaceType(schema:getType("TestInterface"))
			local testType = assertObjectType(schema:getType("TestType"))
			local testScalar = assertScalarType(schema:getType("TestScalar"))
			local testDirective = assertDirective(schema:getDirective("test"))

			expect({
				schema.astNode,
				query.astNode,
				testInput.astNode,
				testEnum.astNode,
				testUnion.astNode,
				testInterface.astNode,
				testType.astNode,
				testScalar.astNode,
				testDirective.astNode,
			}).toObjectContain(ast.definitions)

			local testField = query:getFields().testField

			expect(printASTNode(testField)).to.equal("testField(testArg: TestInput): TestUnion")
			expect(printASTNode(testField.args[1])).to.equal("testArg: TestInput")
			expect(printASTNode(testInput:getFields().testInputField)).to.equal("testInputField: TestEnum")
			expect(printASTNode(testEnum:getValue("TEST_VALUE"))).to.equal("TEST_VALUE")
			expect(printASTNode(testInterface:getFields().interfaceField)).to.equal("interfaceField: String")
			expect(printASTNode(testType:getFields().interfaceField)).to.equal("interfaceField: String")
			expect(printASTNode(testDirective.args[1])).to.equal("arg: TestScalar")
		end)

		it("Root operation types with custom names", function()
			local schema = buildSchema([[

      schema {
        query: SomeQuery
        mutation: SomeMutation
        subscription: SomeSubscription
      }
      type SomeQuery
      type SomeMutation
      type SomeSubscription
    ]])

			expect(schema:getQueryType()).toObjectContain({
				name = "SomeQuery",
			})
			expect(schema:getMutationType()).toObjectContain({
				name = "SomeMutation",
			})
			expect(schema:getSubscriptionType()).toObjectContain({
				name = "SomeSubscription",
			})
		end)

		it("Default root operation type names", function()
			local schema = buildSchema([[

      type Query
      type Mutation
      type Subscription
    ]])

			expect(schema:getQueryType()).toObjectContain({
				name = "Query",
			})
			expect(schema:getMutationType()).toObjectContain({
				name = "Mutation",
			})
			expect(schema:getSubscriptionType()).toObjectContain({
				name = "Subscription",
			})
		end)

		itSKIP("can build invalid schema", function()
			local schema = buildSchema("type Mutation")
			local errors = validateSchema(schema)

			expect(#errors > 0).to.equal(true)
		end)

		it("Do not override standard types", function()
			-- NOTE: not sure it's desired behaviour to just silently ignore override
    		-- attempts so just documenting it here.

			local schema = buildSchema([[

      scalar ID

      scalar __Schema
    ]])

			expect(schema:getType("ID")).to.equal(GraphQLID)
			expect(schema:getType("__Schema")).to.equal(__Schema)
		end)

		it("Allows to reference introspection types", function()
			local schema = buildSchema([[

      type Query {
        introspectionField: __EnumValue
      }
    ]])
			local queryType = assertObjectType(schema:getType("Query"))

			--[[
				ROBLOX deviation: no .to.have.nested.property matcher
				original code: expect(queryType:getFields()).to.have.nested.property("introspectionField.type", __EnumValue)
			--]]
			expect(queryType:getFields().introspectionField.type).to.equal(__EnumValue)
			expect(schema:getType("__EnumValue")).to.equal(__EnumValue)
		end)

		itSKIP("Rejects invalid SDL", function()
			local sdl = [[

      type Query {
        foo: String @unknown
      }
    ]]

			expect(function()
				return buildSchema(sdl)
			end).toThrow("Unknown directive \"@unknown\".")
		end)

		it("Allows to disable SDL validation", function()
			local sdl = [[

      type Query {
        foo: String @unknown
      }
    ]]

			buildSchema(sdl, { assumeValid = true })
			buildSchema(sdl, { assumeValidSDL = true })
		end)

		it("Throws on unknown types", function()
			local sdl = [[

      type Query {
        unknown: UnknownType
      }
    ]]

			expect(function()
				return buildSchema(sdl, { assumeValidSDL = true })
			end).toThrow("Unknown type: \"UnknownType\".")
		end)

		it("Rejects invalid AST", function()
			expect(function()
				return buildASTSchema(nil)
			end).toThrow("Must provide valid Document AST")
			expect(function()
				return buildASTSchema({})
			end).toThrow("Must provide valid Document AST")
		end)
	end)
end
