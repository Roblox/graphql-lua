-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/predicates-test.js

return function()
	local LuauPolyfill = require(script.Parent.Parent.Parent.Parent.Packages.LuauPolyfill)
	local Object = LuauPolyfill.Object
	local Array = LuauPolyfill.Array
	local Kind = require(script.Parent.Parent.kinds).Kind
	local predicates = require(script.Parent.Parent.predicates)

	-- ROBLOX deviation: we need to sort kinds to have deterministic order
	local allKinds = Object.values(Kind)
	table.sort(allKinds)

	local allASTNodes = Array.map(allKinds, function(kind)
		return { kind = kind }
	end)

	local function filterNodes(predicate): Array<string>
		return Array.map(Array.filter(allASTNodes, predicate), function(node)
			return node.kind
		end)
	end

	describe("AST node predicates", function()
		it("isDefinitionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isDefinitionNode)).toEqual({
				"DirectiveDefinition",
				"EnumTypeDefinition",
				"EnumTypeExtension",
				"FragmentDefinition",
				"InputObjectTypeDefinition",
				"InputObjectTypeExtension",
				"InterfaceTypeDefinition",
				"InterfaceTypeExtension",
				"ObjectTypeDefinition",
				"ObjectTypeExtension",
				"OperationDefinition",
				"ScalarTypeDefinition",
				"ScalarTypeExtension",
				"SchemaDefinition",
				"SchemaExtension",
				"UnionTypeDefinition",
				"UnionTypeExtension",
			})
		end)

		it("isExecutableDefinitionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isExecutableDefinitionNode)).toEqual({
				"FragmentDefinition",
				"OperationDefinition",
			})
		end)

		it("isSelectionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isSelectionNode)).toEqual({
				"Field",
				"FragmentSpread",
				"InlineFragment",
			})
		end)

		it("isValueNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isValueNode)).toEqual({
				"BooleanValue",
				"EnumValue",
				"FloatValue",
				"IntValue",
				"ListValue",
				"NullValue",
				"ObjectValue",
				"StringValue",
				"Variable",
			})
		end)

		it("isTypeNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isTypeNode)).toEqual({
				"ListType",
				"NamedType",
				"NonNullType",
			})
		end)

		it("isTypeSystemDefinitionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isTypeSystemDefinitionNode)).toEqual({
				"DirectiveDefinition",
				"EnumTypeDefinition",
				"InputObjectTypeDefinition",
				"InterfaceTypeDefinition",
				"ObjectTypeDefinition",
				"ScalarTypeDefinition",
				"SchemaDefinition",
				"UnionTypeDefinition",
			})
		end)

		it("isTypeDefinitionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isTypeDefinitionNode)).toEqual({
				"EnumTypeDefinition",
				"InputObjectTypeDefinition",
				"InterfaceTypeDefinition",
				"ObjectTypeDefinition",
				"ScalarTypeDefinition",
				"UnionTypeDefinition",
			})
		end)

		it("isTypeSystemExtensionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isTypeSystemExtensionNode)).toEqual({
				"EnumTypeExtension",
				"InputObjectTypeExtension",
				"InterfaceTypeExtension",
				"ObjectTypeExtension",
				"ScalarTypeExtension",
				"SchemaExtension",
				"UnionTypeExtension",
			})
		end)

		it("isTypeExtensionNode", function()
			-- ROBLOX deviation: Order of fields must be alphabetical to keep it deterministic in Lua
			expect(filterNodes(predicates.isTypeExtensionNode)).toEqual({
				"EnumTypeExtension",
				"InputObjectTypeExtension",
				"InterfaceTypeExtension",
				"ObjectTypeExtension",
				"ScalarTypeExtension",
				"UnionTypeExtension",
			})
		end)
	end)
end