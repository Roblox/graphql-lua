-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/833da8281c06b720b56f513818d13bfdf13a06e7/src/utilities/__tests__/TypeInfo-test.js

return function()
	local root = script.Parent.Parent.Parent
	local invariant = require(root.jsutils.invariant).invariant
	local language = root.language
	local parser = require(language.parser)
	local parse = parser.parse
	local parseValue = parser.parseValue
	local print_ = require(language.printer).print
	local visitor = require(language.visitor)
	local visit = visitor.visit
	local definition = require(root.type.definition)
	local getNamedType = definition.getNamedType
	local isCompositeType = definition.isCompositeType
	local utilities = root.utilities
	local buildASTSchema = require(utilities.buildASTSchema)
	local buildSchema = buildASTSchema.buildSchema
	local TypeInfoExports = require(utilities.TypeInfo)
	local TypeInfo = TypeInfoExports.TypeInfo
	local visitWithTypeInfo = TypeInfoExports.visitWithTypeInfo
	local harness = require(root.validation.__tests__.harness)
	local testSchema = harness.testSchema

	local Packages = root.Parent.Packages
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Object = LuauPolyfill.Object

	local NULL = "$NULL SYMBOL"
	local function wrapNullArgs(...)
		local args = {}
		for i = 1, select("#", ...) do
			local arg = select(i, ...)
			if arg == nil then
				args[i] = NULL
			else
				args[i] = arg
			end
		end
		return unpack(args)
	end

	describe("TypeInfo", function()
		it("allow all methods to be called before entering any node", function()
			local typeInfo = TypeInfo.new(testSchema)

			expect(typeInfo:getType()).to.equal(nil)
			expect(typeInfo:getParentType()).to.equal(nil)
			expect(typeInfo:getInputType()).to.equal(nil)
			expect(typeInfo:getParentInputType()).to.equal(nil)
			expect(typeInfo:getFieldDef()).to.equal(nil)
			expect(typeInfo:getDefaultValue()).to.equal(nil)
			expect(typeInfo:getDirective()).to.equal(nil)
			expect(typeInfo:getArgument()).to.equal(nil)
			expect(typeInfo:getEnumValue()).to.equal(nil)
		end)
	end)

	describe("visitWithTypeInfo", function()
		it("supports different operation types", function()
			local schema = buildSchema([[
				schema {
					query: QueryRoot
					mutation: MutationRoot
					subscription: SubscriptionRoot
				}

				type QueryRoot {
					foo: String
				}

				type MutationRoot {
					bar: String
				}

				type SubscriptionRoot {
					baz: String
				}
			]])
			local ast = parse([[
				query { foo }
				mutation { bar }
				subscription { baz }
			]])
			local typeInfo = TypeInfo.new(schema)

			local rootTypes = {}

			visit(
				ast,
				visitWithTypeInfo(typeInfo, {
					OperationDefinition = function(_self, node)
						rootTypes[node.operation] = typeInfo:getType():toString()
					end,
				})
			)
			expect(rootTypes).toEqual({
				query = "QueryRoot",
				mutation = "MutationRoot",
				subscription = "SubscriptionRoot",
			})
		end)

		it("provide exact same arguments to wrapped visitor", function()
			local ast = parse(
				"{ human(id: 4) { name, pets { ... { name } }, unknown } }"
			)
			local visitorArgs = {}
			visit(ast, {
				enter = function(_self, ...)
					table.insert(visitorArgs, {"enter", wrapNullArgs(...)})
				end,
				leave = function(_self, ...)
					table.insert(visitorArgs, {"leave", wrapNullArgs(...)})
				end,
			})

			local wrappedVisitorArgs = {}
			local typeInfo = TypeInfo.new(testSchema)
			visit(ast, visitWithTypeInfo(typeInfo, {
				enter = function(_self, ...)
					table.insert(wrappedVisitorArgs, {"enter", wrapNullArgs(...)})
				end,
				leave = function(_self, ...)
					table.insert(wrappedVisitorArgs, {"leave", wrapNullArgs(...)})
				end,
			}))

			expect(visitorArgs).toEqual(wrappedVisitorArgs)
		end)

		itSKIP("maintains type info during visit", function()
			local visited = {}
			local typeInfo = TypeInfo.new(testSchema)
			local ast = parse("{ human(id: 4) { name, pets { ... { name } }, unknown } }")

			visit(ast, visitWithTypeInfo(typeInfo, {
				enter = function(_self, node)
					local parentType = typeInfo:getParentType()
					local type_ = typeInfo:getType()
					local inputType = typeInfo:getInputType()

					table.insert(visited, {
						"enter",
						node.kind,
						node.kind == "Name" and node.value or NULL,
						parentType and parentType:toString() or NULL,
						type_ and type_:toString() or NULL,
						inputType and inputType:toString() or NULL,
					})
				end,
				leave = function(_self, node)
					local parentType = typeInfo:getParentType()
					local type_ = typeInfo:getType()
					local inputType = typeInfo:getInputType()

					table.insert(visited, {
						"leave",
						node.kind,
						node.kind == "Name" and node.value or NULL,
						parentType and parentType:toString() or NULL,
						type_ and type_:toString() or NULL,
						inputType and inputType:toString() or NULL,
					})
				end,
			}))

			expect(visited).toEqual({
				{"enter", "Document", NULL, NULL, NULL, NULL},
				{"enter", "OperationDefinition", NULL, NULL, "QueryRoot", NULL},
				{"enter", "SelectionSet", NULL, "QueryRoot", "QueryRoot", NULL},
				{"enter", "Field", NULL, "QueryRoot", "Human", NULL},
				{"enter", "Name", "human", "QueryRoot", "Human", NULL},
				{"leave", "Name", "human", "QueryRoot", "Human", NULL},
				{"enter", "Argument", NULL, "QueryRoot", "Human", "ID"},
				{"enter", "Name", "id", "QueryRoot", "Human", "ID"},
				{"leave", "Name", "id", "QueryRoot", "Human", "ID"},
				{"enter", "IntValue", NULL, "QueryRoot", "Human", "ID"},
				{"leave", "IntValue", NULL, "QueryRoot", "Human", "ID"},
				{"leave", "Argument", NULL, "QueryRoot", "Human", "ID"},
				{"enter", "SelectionSet", NULL, "Human", "Human", NULL},
				{"enter", "Field", NULL, "Human", "String", NULL},
				{"enter", "Name", "name", "Human", "String", NULL},
				{"leave", "Name", "name", "Human", "String", NULL},
				{"leave", "Field", NULL, "Human", "String", NULL},
				{"enter", "Field", NULL, "Human", "[Pet]", NULL},
				{"enter", "Name", "pets", "Human", "[Pet]", NULL},
				{"leave", "Name", "pets", "Human", "[Pet]", NULL},
				{"enter", "SelectionSet", NULL, "Pet", "[Pet]", NULL},
				{"enter", "InlineFragment", NULL, "Pet", "Pet", NULL},
				{"enter", "SelectionSet", NULL, "Pet", "Pet", NULL},
				{"enter", "Field", NULL, "Pet", "String", NULL},
				{"enter", "Name", "name", "Pet", "String", NULL},
				{"leave", "Name", "name", "Pet", "String", NULL},
				{"leave", "Field", NULL, "Pet", "String", NULL},
				{"leave", "SelectionSet", NULL, "Pet", "Pet", NULL},
				{"leave", "InlineFragment", NULL, "Pet", "Pet", NULL},
				{"leave", "SelectionSet", NULL, "Pet", "[Pet]", NULL},
				{"leave", "Field", NULL, "Human", "[Pet]", NULL},
				{"enter", "Field", NULL, "Human", NULL, NULL},
				{"enter", "Name", "unknown", "Human", NULL, NULL},
				{"leave", "Name", "unknown", "Human", NULL, NULL},
				{"leave", "Field", NULL, "Human", NULL, NULL},
				{"leave", "SelectionSet", NULL, "Human", "Human", NULL},
				{"leave", "Field", NULL, "QueryRoot", "Human", NULL},
				{"leave", "SelectionSet", NULL, "QueryRoot", "QueryRoot", NULL},
				{"leave", "OperationDefinition", NULL, NULL, "QueryRoot", NULL},
				{"leave", "Document", NULL, NULL, NULL, NULL},
			})
		end)

		itSKIP("maintains type info during edit", function()
			local visited = {}
			local typeInfo = TypeInfo.new(testSchema)

			local ast = parse("{ human(id: 4) { name, pets }, alien }")
			local editedAST = visit(
				ast,
				visitWithTypeInfo(typeInfo, {
					enter = function(_self, node)
						local parentType = typeInfo:getParentType()
						local type_ = typeInfo:getType()
						local inputType = typeInfo:getInputType()
						table.insert(visited, {
							"enter",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							parentType and parentType:toString() or NULL,
							type_ and type_:toString() or NULL,
							inputType and inputType:toString() or NULL,
						})

						-- // Make a query valid by adding missing selection sets.
						if
							node.kind == "Field" and
							not node.selectionSet and
							isCompositeType(getNamedType(type))
						then
							return Object.Assign(
								{},
								node,
								{
									selectionSet = {
										kind = "SelectionSet",
										selections = {
											{
												kind = "Field",
												name = { kind = "Name", value = "__typename" },
											},
										},
									},
								}
							)
						end
						return nil
					end,
					leave = function(_self, node)
						local parentType = typeInfo:getParentType()
						local type_ = typeInfo:getType()
						local inputType = typeInfo:getInputType()
						table.insert(visited, {
							"leave",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							parentType and parentType:toString() or NULL,
							type_ and type_:toString() or NULL,
							inputType and inputType:toString() or NULL,
						})
					end,
				})
			)

			expect(print_(ast)).toEqual(
				print_(parse("{ human(id: 4) { name, pets }, alien }"))
			)
			expect(print_(editedAST)).toEqual(
				print_(
					parse(
						"{ human(id: 4) { name, pets { __typename } }, alien { __typename } }"
					)
				)
			)

			expect(visited).toEqual({
				{"enter", "Document", NULL, NULL, NULL, NULL},
				{"enter", "OperationDefinition", NULL, NULL, "QueryRoot", NULL},
				{"enter", "SelectionSet", NULL, "QueryRoot", "QueryRoot", NULL},
				{"enter", "Field", NULL, "QueryRoot", "Human", NULL},
				{"enter", "Name", "human", "QueryRoot", "Human", NULL},
				{"leave", "Name", "human", "QueryRoot", "Human", NULL},
				{"enter", "Argument", NULL, "QueryRoot", "Human", "ID"},
				{"enter", "Name", "id", "QueryRoot", "Human", "ID"},
				{"leave", "Name", "id", "QueryRoot", "Human", "ID"},
				{"enter", "IntValue", NULL, "QueryRoot", "Human", "ID"},
				{"leave", "IntValue", NULL, "QueryRoot", "Human", "ID"},
				{"leave", "Argument", NULL, "QueryRoot", "Human", "ID"},
				{"enter", "SelectionSet", NULL, "Human", "Human", NULL},
				{"enter", "Field", NULL, "Human", "String", NULL},
				{"enter", "Name", "name", "Human", "String", NULL},
				{"leave", "Name", "name", "Human", "String", NULL},
				{"leave", "Field", NULL, "Human", "String", NULL},
				{"enter", "Field", NULL, "Human", "[Pet]", NULL},
				{"enter", "Name", "pets", "Human", "[Pet]", NULL},
				{"leave", "Name", "pets", "Human", "[Pet]", NULL},
				{"enter", "SelectionSet", NULL, "Pet", "[Pet]", NULL},
				{"enter", "Field", NULL, "Pet", "String!", NULL},
				{"enter", "Name", "__typename", "Pet", "String!", NULL},
				{"leave", "Name", "__typename", "Pet", "String!", NULL},
				{"leave", "Field", NULL, "Pet", "String!", NULL},
				{"leave", "SelectionSet", NULL, "Pet", "[Pet]", NULL},
				{"leave", "Field", NULL, "Human", "[Pet]", NULL},
				{"leave", "SelectionSet", NULL, "Human", "Human", NULL},
				{"leave", "Field", NULL, "QueryRoot", "Human", NULL},
				{"enter", "Field", NULL, "QueryRoot", "Alien", NULL},
				{"enter", "Name", "alien", "QueryRoot", "Alien", NULL},
				{"leave", "Name", "alien", "QueryRoot", "Alien", NULL},
				{"enter", "SelectionSet", NULL, "Alien", "Alien", NULL},
				{"enter", "Field", NULL, "Alien", "String!", NULL},
				{"enter", "Name", "__typename", "Alien", "String!", NULL},
				{"leave", "Name", "__typename", "Alien", "String!", NULL},
				{"leave", "Field", NULL, "Alien", "String!", NULL},
				{"leave", "SelectionSet", NULL, "Alien", "Alien", NULL},
				{"leave", "Field", NULL, "QueryRoot", "Alien", NULL},
				{"leave", "SelectionSet", NULL, "QueryRoot", "QueryRoot", NULL},
				{"leave", "OperationDefinition", NULL, NULL, "QueryRoot", NULL},
				{"leave", "Document", NULL, NULL, NULL, NULL},
			})
		end)

		it("supports traversals of input values", function()
			local ast = parseValue('{ stringListField: ["foo"] }')
			local complexInputType = testSchema:getType("ComplexInput")

			invariant(complexInputType ~= nil)

			local typeInfo = TypeInfo.new(testSchema, nil, complexInputType)
			local visited = {}

			visit(
				ast,
				visitWithTypeInfo(typeInfo, {
					enter = function(_self, node)
						local type_ = typeInfo:getInputType()
						table.insert(visited, {
							"enter",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							type_:toString(),
						})
					end,
					leave = function(_self, node)
						local type_ = typeInfo:getInputType()
						table.insert(visited, {
							"leave",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							type_:toString(),
						})
					end,
				})
			)
			expect(visited).toEqual({
				{"enter", "ObjectValue", NULL, "ComplexInput"},
				{"enter", "ObjectField", NULL, "[String]"},
				{"enter", "Name", "stringListField", "[String]"},
				{"leave", "Name", "stringListField", "[String]"},
				{"enter", "ListValue", NULL, "String"},
				{"enter", "StringValue", NULL, "String"},
				{"leave", "StringValue", NULL, "String"},
				{"leave", "ListValue", NULL, "String"},
				{"leave", "ObjectField", NULL, "[String]"},
				{"leave", "ObjectValue", NULL, "ComplexInput"},
			})
		end)

		it("supports traversals of selection sets", function()
			local humanType = testSchema:getType("Human")
			invariant(humanType ~= nil)

			local typeInfo = TypeInfo.new(testSchema, nil, humanType)

			local ast = parse("{ name, pets { name } }")
			local operationNode = ast.definitions[1]
			invariant(operationNode.kind == "OperationDefinition")

			local visited = {}

			visit(
				operationNode.selectionSet,
				visitWithTypeInfo(typeInfo, {
					enter = function(_self, node)
						local parentType = typeInfo:getParentType()
						local type_ = typeInfo:getType()
						table.insert(visited, {
							"enter",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							parentType:toString(),
							type_:toString(),
						})
					end,
					leave = function(_self, node)
						local parentType = typeInfo:getParentType()
						local type_ = typeInfo:getType()
						table.insert(visited, {
							"leave",
							node.kind,
							node.kind == "Name" and node.value or NULL,
							parentType:toString(),
							type_:toString(),
						})
					end,
				})
			)

			expect(visited).toEqual({
				{"enter", "SelectionSet", NULL, "Human", "Human"},
				{"enter", "Field", NULL, "Human", "String"},
				{"enter", "Name", "name", "Human", "String"},
				{"leave", "Name", "name", "Human", "String"},
				{"leave", "Field", NULL, "Human", "String"},
				{"enter", "Field", NULL, "Human", "[Pet]"},
				{"enter", "Name", "pets", "Human", "[Pet]"},
				{"leave", "Name", "pets", "Human", "[Pet]"},
				{"enter", "SelectionSet", NULL, "Pet", "[Pet]"},
				{"enter", "Field", NULL, "Pet", "String"},
				{"enter", "Name", "name", "Pet", "String"},
				{"leave", "Name", "name", "Pet", "String"},
				{"leave", "Field", NULL, "Pet", "String"},
				{"leave", "SelectionSet", NULL, "Pet", "[Pet]"},
				{"leave", "Field", NULL, "Human", "[Pet]"},
				{"leave", "SelectionSet", NULL, "Human", "Human"},
			})
		end)
	end)
end
