-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/error/__tests__/GraphQLError-test.js
--!nolint ImportUnused
--!nolint LocalUnused

return function()

	-- directory
	local errorWorkspace = script.Parent.Parent
	local srcWorkspace = errorWorkspace.Parent
	local rootWorkspace = srcWorkspace.Parent
	local Packages = rootWorkspace.Packages
	local languageWorkspace = srcWorkspace.language

	-- require
	local dedent = require(srcWorkspace.__testUtils__.dedent)
	local invariant = require(srcWorkspace.jsutils.invariant)
	local Kind = require(languageWorkspace.kinds)
	local parse = require(languageWorkspace.parser).parse
	local Source = require(languageWorkspace.source).Source
	local GraphQLError = require(errorWorkspace.GraphQLError).GraphQLError

	-- lua helpers & polyfills
	local instanceOf = require(srcWorkspace.jsutils.instanceOf)
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Error = require(srcWorkspace.luaUtils.Error)

	local source = Source.new(dedent([[
		{
		field
		}
	]]))
	-- local ast = parse(source);
	-- local operationNode = ast.definitions[1];
	-- invariant(operationNode.kind == Kind.OPERATION_DEFINITION);
	local fieldNode = { loc = { source = source } } -- operationNode.selectionSet.selections[1];
	-- invariant(fieldNode);

	describe("GraphQLError", function()
		it("is a class and is a subclass of Error", function()
			local instance = GraphQLError.new("str")
			expect(instanceOf(instance, GraphQLError)).to.equal(true)
			expect(instanceOf(instance, Error)).to.equal(true)
		end)

		it("has a name, message, and stack trace", function()
			local e = GraphQLError.new("msg")

			expect(e.name).to.equal("GraphQLError")
			expect(e.message).to.equal("msg")
			expect(e.stack).to.be.a("string")
		end)

		it("uses the stack of an original error", function()
			local original = Error.new("original")
			local e = GraphQLError.new("msg", nil, nil, nil, nil, original)

			expect(e.name).to.equal("GraphQLError")
			expect(e.message).to.equal("msg")
			expect(e.stack).to.equal(original.stack)
			expect(e.originalError).to.equal(original)
		end)

		it("creates new stack if original error has no stack", function()
			local original = Error.new("original")
			local e = GraphQLError.new("msg", nil, nil, nil, nil, original)

			expect(e.name).to.equal("GraphQLError")
			expect(e.message).to.equal("msg")
			expect(e.originalError).to.equal(original)
			expect(e.stack).to.be.a("string")
		end)

		itSKIP("converts nodes to positions and locations", function()
			local e = GraphQLError.new("msg", { fieldNode })
			-- TODO
			-- expect(e).to.deep.include({
			-- 	nodes = {fieldNode},
			-- 	positions = {4},
			-- 	locations = {{ line = 2, column = 3 }},
			-- });
			expect(e.source).to.equal(source)
		end)

		itSKIP("converts single node to positions and locations", function()
			local e = GraphQLError.new("msg", fieldNode)
			-- TODO
			-- expect(e).to.deep.include({
			-- 	nodes = {fieldNode},
			-- 	positions = {4},
			-- 	locations = {{ line = 2, column = 3 }},
			-- });
			expect(true).to.equal(false)
		end)

		itSKIP("converts node with loc.start === 0 to positions and locations", function()
			-- const e = new GraphQLError('msg', operationNode);
			-- expect(e).to.have.property('source', source);
			-- expect(e).to.deep.include({
			--   nodes: [operationNode],
			--   positions: [0],
			--   locations: [{ line: 1, column: 1 }],
			-- });
		end)

		itSKIP("converts source and positions to locations", function()
			-- const e = new GraphQLError('msg', null, source, [6]);
			-- expect(e).to.have.property('source', source);
			-- expect(e).to.deep.include({
			--   nodes: undefined,
			--   positions: [6],
			--   locations: [{ line: 2, column: 5 }],
			-- });
		end)

		itSKIP("serializes to include message", function()
			-- const e = new GraphQLError('msg');
			-- expect(JSON.stringify(e)).to.equal('{"message":"msg"}');
		end)

		itSKIP("serializes to include message and locations", function()
			-- const e = new GraphQLError('msg', fieldNode);
			-- expect(JSON.stringify(e)).to.equal(
			--   '{"message":"msg","locations":[{"line":2,"column":3}]}',
			-- );
		end)

		itSKIP("serializes to include path", function()
			-- const e = new GraphQLError('msg', null, null, null, [
			-- 	'path',
			-- 	3,
			-- 	'to',
			-- 	'field',
			--   ]);
			--   expect(e).to.have.deep.property('path', ['path', 3, 'to', 'field']);
			--   expect(JSON.stringify(e)).to.equal(
			-- 	'{"message":"msg","path":["path",3,"to","field"]}',
			--   );
		end)
	end)

	describe("printError", function()

		itSKIP("prints an error without location", function()
			-- local error = GraphQLError.new('Error without location');
			-- expect(printError(error)).to.equal('Error without location');
		end)

		itSKIP("prints an error using node without location", function()
			-- const error = new GraphQLError(
			--   'Error attached to node without location',
			--   parse('{ foo }', { noLocation: true }),
			-- );
			-- expect(printError(error)).to.equal(
			--   'Error attached to node without location',
			-- );
		end)

		itSKIP("prints an error with nodes from different sources", function()
			-- const docA = parse(
			--   new Source(
			-- 	dedent`
			-- 	  type Foo {
			-- 		field: String
			-- 	  }
			-- 	`,
			-- 	'SourceA',
			--   ),
			-- );
			-- const opA = docA.definitions[0];
			-- invariant(opA.kind === Kind.OBJECT_TYPE_DEFINITION && opA.fields);
			-- const fieldA = opA.fields[0];

			-- const docB = parse(
			--   new Source(
			-- 	dedent`
			-- 	  type Foo {
			-- 		field: Int
			-- 	  }
			-- 	`,
			-- 	'SourceB',
			--   ),
			-- );
			-- const opB = docB.definitions[0];
			-- invariant(opB.kind === Kind.OBJECT_TYPE_DEFINITION && opB.fields);
			-- const fieldB = opB.fields[0];

			-- const error = new GraphQLError('Example error with two nodes', [
			--   fieldA.type,
			--   fieldB.type,
			-- ]);

			-- expect(printError(error) + '\n').to.equal(dedent`
			--   Example error with two nodes

			--   SourceA:2:10
			--   1 | type Foo {
			--   2 |   field: String
			-- 	|          ^
			--   3 | }

			--   SourceB:2:10
			--   1 | type Foo {
			--   2 |   field: Int
			-- 	|          ^
			--   3 | }
			-- `);
		end)

	end)

end
