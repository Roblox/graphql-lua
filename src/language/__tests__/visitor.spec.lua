-- upstream https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/language/__tests__/visitor-test.js

return function()
	local srcWorkspace = script.Parent.Parent.Parent
	local root = srcWorkspace.Parent
	local LuauPolyfill = require(root.Packages.LuauPolyfill)
	local UtilArray = require(srcWorkspace.luaUtils.Array)
	local Array = LuauPolyfill.Array
	local Object = LuauPolyfill.Object

	local kitchenSinkQuery = require(srcWorkspace.__fixtures__).kitchenSinkQuery

	local invariant = require(srcWorkspace.jsutils.invariant).invariant

	local Kind = require(script.Parent.Parent.kinds).Kind
	local parse = require(script.Parent.Parent.parser).parse
	local visitorExports = require(script.Parent.Parent.visitor)
	local visit = visitorExports.visit
	local visitInParallel = visitorExports.visitInParallel
	local BREAK = visitorExports.BREAK
	local NULL = require(srcWorkspace.luaUtils.null)
	local QueryDocumentKeys = visitorExports.QueryDocumentKeys

	-- ROBLOX deviation: expect cannot be called unless inside of an it
	-- ROBLOX deviation: pass expect into this function and use local scope
	local function checkVisitorFnArgs(expect_, ast, args, isEdited)
		local node, key, parent, path, ancestors = table.unpack(args)

		expect_(node).to.be.a("table")
		expect_(node.kind).toBeOneOf(Object.values(Kind))

		local isRoot = key == nil
		if isRoot then
			if not isEdited then
				expect_(node).toEqual(ast)
			end
			expect_(parent).to.equal(nil)
			expect_(path).toEqual({})
			expect_(ancestors).toEqual({})
			return
		end

		expect_(typeof(key)).toBeOneOf({ "number", "string" })

		-- ROBLOX deviation: JS -> expect(parent).to.have.property(key)
		-- if a property was null or undefined in JS in would not be present in Lua
		-- so we are just checking if a parent is a table
		expect_(typeof(parent)).to.equal("table")

		expect_(Array.isArray(path)).to.equal(true)
		expect_(path[#path]).to.equal(key)

		expect_(Array.isArray(ancestors)).to.equal(true)
		expect_(#ancestors).to.equal(#path - 1)

		if not isEdited then
			local currentNode = ast
			for i = 1, #ancestors do
				expect_(ancestors[i]).to.equal(currentNode)

				currentNode = currentNode[path[i]]
				expect_(currentNode).never.to.equal(nil)
			end

			expect_(parent).to.equal(currentNode)
			expect_(parent[key]).to.equal(node)
		end
	end

	local function getValue(node)
		return node.value
	end

	describe("Visitor", function()
		it("validates path argument", function()
			local visited = {}
			local ast = parse("{ a }", { noLocation = true })

			visit(ast, {
				enter = function(self, ...)
					local _node, _key, _parent, path = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", Array.slice(path) })
				end,
				leave = function(self, ...)
					local _node, _key, _parent, path = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "leave", Array.slice(path) })
				end,
			})

			expect(visited).toEqual({
				{ "enter", {} },
				{ "enter", { "definitions", 1 } },
				{ "enter", { "definitions", 1, "selectionSet" } },
				{ "enter", { "definitions", 1, "selectionSet", "selections", 1 } },
				{
					"enter",
					{ "definitions", 1, "selectionSet", "selections", 1, "name" },
				},
				{
					"leave",
					{ "definitions", 1, "selectionSet", "selections", 1, "name" },
				},
				{ "leave", { "definitions", 1, "selectionSet", "selections", 1 } },
				{ "leave", { "definitions", 1, "selectionSet" } },
				{ "leave", { "definitions", 1 } },
				{ "leave", {} },
			})
		end)

		it("validates ancestors argument", function()
			local ast = parse("{ a }", { noLocation = true })
			local visitedNodes = {}

			visit(ast, {
				enter = function(self, ...)
					local node, key, parent, _path, ancestors = ...
					local inArray = typeof(key) == "number"
					if inArray then
						table.insert(visitedNodes, parent)
					end
					table.insert(visitedNodes, node)

					local expectedAncestors = Array.slice(visitedNodes, 1, -1)
					expect(ancestors).toEqual(expectedAncestors)
				end,
				leave = function(self, ...)
					local _node, key, _parent, _path, ancestors = ...
					local expectedAncestors = Array.slice(visitedNodes, 1, -1)
					expect(ancestors).toEqual(expectedAncestors)

					local inArray = typeof(key) == "number"
					if inArray then
						table.remove(visitedNodes)
					end
					table.remove(visitedNodes)
				end,
			})
		end)

		it("allows visiting only specified nodes", function()
			local ast = parse("{ a }", { noLocation = true })
			local visited = {}

			visit(ast, {
				enter = {
					Field = function(self, node)
						table.insert(visited, { "enter", node.kind })
					end,
				},
				leave = {
					Field = function(self, node)
						table.insert(visited, { "leave", node.kind })
					end,
				},
			})

			expect(visited).toEqual({
				{ "enter", "Field" },
				{ "leave", "Field" },
			})
		end)

		it("allows editing a node both on enter and on leave", function()
			local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })

			local selectionSet

			local editedAST = visit(ast, {
				OperationDefinition = {
					enter = function(self, ...)
						local node = ...
						checkVisitorFnArgs(expect, ast, { ... })
						selectionSet = node.selectionSet
						return Object.assign({}, node, {
							selectionSet = {
								kind = "SelectionSet",
								selections = {},
							},
							didEnter = true,
						})
					end,
					leave = function(self, ...)
						local node = ...
						checkVisitorFnArgs(
							expect,
							ast,
							{ ... },
							true --[[ isEdited ]]
						)
						return Object.assign({}, node, {
							selectionSet = selectionSet,
							didLeave = true,
						})
					end,
				},
			})

			expect(editedAST).toEqual(Object.assign({}, ast, {
				definitions = {
					Object.assign({}, ast.definitions[1], {
						didEnter = true,
						didLeave = true,
					}),
				},
			}))
		end)

		it("allows editing the root node on enter and on leave", function()
			local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })

			local definitions = ast.definitions

			local editedAST = visit(ast, {
				Document = {
					enter = function(self, ...)
						local node = ...
						checkVisitorFnArgs(expect, ast, { ... })
						return Object.assign({}, node, {
							definitions = {},
							didEnter = true,
						})
					end,
					leave = function(self, ...)
						local node = ...
						checkVisitorFnArgs(
							expect,
							ast,
							{ ... },
							true --[[ isEdited ]]
						)
						return Object.assign({}, node, {
							definitions = definitions,
							didLeave = true,
						})
					end,
				},
			})

			expect(editedAST).toEqual(Object.assign({}, ast, {
				didEnter = true,
				didLeave = true,
			}))
		end)

		it("allows for editing on enter", function()
			local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })
			local editedAST = visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					if node.kind == "Field" and node.name.value == "b" then
						return NULL -- ROBLOX deviation: returning NULL instead of null in JS to distinguish between undefined
					end
					return -- ROBLOX deviation: no implicit returns
				end,
			})

			expect(ast).toEqual(parse("{ a, b, c { a, b, c } }", { noLocation = true }))

			expect(editedAST).toEqual(parse("{ a,    c { a,    c } }", { noLocation = true }))
		end)

		it("allows for editing on leave", function()
			local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })
			local editedAST = visit(ast, {
				leave = function(self, ...)
					local node = ...
					checkVisitorFnArgs(
						expect,
						ast,
						{ ... },
						true --[[ isEdited ]]
					)
					if node.kind == "Field" and node.name.value == "b" then
						return NULL -- ROBLOX deviation: returning NULL instead of null in JS to distinguish between undefined
					end
					return -- ROBLOX deviation: no implicit returns
				end,
			})

			expect(ast).toEqual(parse("{ a, b, c { a, b, c } }", { noLocation = true }))

			expect(editedAST).toEqual(parse("{ a,    c { a,    c } }", { noLocation = true }))
		end)

		it("ignores false returned on leave", function()
			local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })
			local returnedAST = visit(ast, {
				leave = function()
					return false
				end,
			})

			expect(returnedAST).toEqual(parse("{ a, b, c { a, b, c } }", { noLocation = true }))
		end)

		it("visits edited node", function()
			local addedField = {
				kind = "Field",
				name = {
					kind = "Name",
					value = "__typename",
				},
			}

			local didVisitAddedField

			local ast = parse("{ a { x } }", { noLocation = true })
			visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(
						expect,
						ast,
						{ ... },
						true --[[ isEdited ]]
					)
					if node.kind == "Field" and node.name.value == "a" then
						return {
							kind = "Field",
							selectionSet = UtilArray.concat({ addedField }, node.selectionSet),
						}
					end
					if node == addedField then
						didVisitAddedField = true
					end
					return -- ROBLOX deviation: no implicit returns
				end,
			})

			expect(didVisitAddedField).to.equal(true)
		end)

		it("allows skipping a sub-tree", function()
			local visited = {}

			local ast = parse("{ a, b { x }, c }", { noLocation = true })
			visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", node.kind, getValue(node) })
					if node.kind == "Field" and node.name.value == "b" then
						return false
					end
					return -- ROBLOX deviation: no implicit returns
				end,

				leave = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "leave", node.kind, getValue(node) })
				end,
			})

			expect(visited).toEqual({
				{ "enter", "Document" },
				{ "enter", "OperationDefinition" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field" },
				{ "enter", "Field" },
				{ "enter", "Field" },
				{ "enter", "Name", "c" },
				{ "leave", "Name", "c" },
				{ "leave", "Field" },
				{ "leave", "SelectionSet" },
				{ "leave", "OperationDefinition" },
				{ "leave", "Document" },
			})
		end)

		it("allows early exit while visiting", function()
			local visited = {}

			local ast = parse("{ a, b { x }, c }", { noLocation = true })
			visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", node.kind, getValue(node) })
					if node.kind == "Name" and node.value == "x" then
						return BREAK
					end
					return -- ROBLOX deviation: no implicit returns
				end,
				leave = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "leave", node.kind, getValue(node) })
				end,
			})

			expect(visited).toEqual({
				{ "enter", "Document" },
				{ "enter", "OperationDefinition" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field" },
				{ "enter", "Field" },
				{ "enter", "Name", "b" },
				{ "leave", "Name", "b" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "x" },
			})
		end)

		it("allows early exit while leaving", function()
			local visited = {}

			local ast = parse("{ a, b { x }, c }", { noLocation = true })
			visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", node.kind, getValue(node) })
				end,
				leave = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "leave", node.kind, getValue(node) })
					if node.kind == "Name" and node.value == "x" then
						return BREAK
					end
					return -- ROBLOX deviation: no implicit returns
				end,
			})

			expect(visited).toEqual({
				{ "enter", "Document" },
				{ "enter", "OperationDefinition" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field" },
				{ "enter", "Field" },
				{ "enter", "Name", "b" },
				{ "leave", "Name", "b" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "x" },
				{ "leave", "Name", "x" },
			})
		end)

		it("allows a named functions visitor API", function()
			local visited = {}

			local ast = parse("{ a, b { x }, c }", { noLocation = true })
			visit(ast, {
				Name = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", node.kind, getValue(node) })
				end,
				SelectionSet = {
					enter = function(self, ...)
						local node = ...
						checkVisitorFnArgs(expect, ast, { ... })
						table.insert(visited, { "enter", node.kind, getValue(node) })
					end,
					leave = function(self, ...)
						local node = ...
						checkVisitorFnArgs(expect, ast, { ... })
						table.insert(visited, { "leave", node.kind, getValue(node) })
					end,
				},
			})

			expect(visited).toEqual({
				{ "enter", "SelectionSet" },
				{ "enter", "Name", "a" },
				{ "enter", "Name", "b" },
				{ "enter", "SelectionSet" },
				{ "enter", "Name", "x" },
				{ "leave", "SelectionSet" },
				{ "enter", "Name", "c" },
				{ "leave", "SelectionSet" },
			})
		end)

		it("Experimental: visits variables defined in fragments", function()
			local ast = parse("fragment a($v: Boolean = false) on t { f }", {
				noLocation = true,
				experimentalFragmentVariables = true,
			})
			local visited = {}

			visit(ast, {
				enter = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "enter", node.kind, getValue(node) })
				end,
				leave = function(self, ...)
					local node = ...
					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(visited, { "leave", node.kind, getValue(node) })
				end,
			})

			expect(visited).toEqual({
				{ "enter", "Document" },
				{ "enter", "FragmentDefinition" },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "enter", "VariableDefinition" },
				{ "enter", "Variable" },
				{ "enter", "Name", "v" },
				{ "leave", "Name", "v" },
				{ "leave", "Variable" },
				{ "enter", "NamedType" },
				{ "enter", "Name", "Boolean" },
				{ "leave", "Name", "Boolean" },
				{ "leave", "NamedType" },
				{ "enter", "BooleanValue", false },
				{ "leave", "BooleanValue", false },
				{ "leave", "VariableDefinition" },
				{ "enter", "NamedType" },
				{ "enter", "Name", "t" },
				{ "leave", "Name", "t" },
				{ "leave", "NamedType" },
				{ "enter", "SelectionSet" },
				{ "enter", "Field" },
				{ "enter", "Name", "f" },
				{ "leave", "Name", "f" },
				{ "leave", "Field" },
				{ "leave", "SelectionSet" },
				{ "leave", "FragmentDefinition" },
				{ "leave", "Document" },
			})
		end)

		it("visits kitchen sink", function()
			local ast = parse(kitchenSinkQuery)
			local visited = {}
			local argsStack = {}

			visit(ast, {
				enter = function(self, ...)
					local node, key, parent = ...
					table.insert(visited, {
						"enter",
						node.kind,
						key,
						(parent and parent.kind) ~= nil and parent.kind or nil,
					})

					checkVisitorFnArgs(expect, ast, { ... })
					table.insert(argsStack, { ... })
				end,
				leave = function(self, ...)
					local node, key, parent = ...
					table.insert(visited, {
						"leave",
						node.kind,
						key,
						(parent and parent.kind) ~= nil and parent.kind or nil,
					})

					expect(table.remove(argsStack)).toEqual({ ... })
				end,
			})

			expect(argsStack).toEqual({})
			expect(visited).toEqual({
				{ "enter", "Document" },
				{ "enter", "OperationDefinition", 1 },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "VariableDefinition", 1 },
				{ "enter", "Variable", "variable", "VariableDefinition" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "variable", "VariableDefinition" },
				{ "enter", "NamedType", "type", "VariableDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "type", "VariableDefinition" },
				{ "leave", "VariableDefinition", 1 },
				{ "enter", "VariableDefinition", 2 },
				{ "enter", "Variable", "variable", "VariableDefinition" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "variable", "VariableDefinition" },
				{ "enter", "NamedType", "type", "VariableDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "type", "VariableDefinition" },
				{ "enter", "EnumValue", "defaultValue", "VariableDefinition" },
				{ "leave", "EnumValue", "defaultValue", "VariableDefinition" },
				{ "leave", "VariableDefinition", 2 },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "alias", "Field" },
				{ "leave", "Name", "alias", "Field" },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "ListValue", "value", "Argument" },
				{ "enter", "IntValue", 1 },
				{ "leave", "IntValue", 1 },
				{ "enter", "IntValue", 2 },
				{ "leave", "IntValue", 2 },
				{ "leave", "ListValue", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "enter", "InlineFragment", 2 },
				{ "enter", "NamedType", "typeCondition", "InlineFragment" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "typeCondition", "InlineFragment" },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "enter", "Field", 2 },
				{ "enter", "Name", "alias", "Field" },
				{ "leave", "Name", "alias", "Field" },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "IntValue", "value", "Argument" },
				{ "leave", "IntValue", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "Argument", 2 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 2 },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "enter", "FragmentSpread", 2 },
				{ "enter", "Name", "name", "FragmentSpread" },
				{ "leave", "Name", "name", "FragmentSpread" },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "leave", "FragmentSpread", 2 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 2 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 2 },
				{ "enter", "InlineFragment", 3 },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 3 },
				{ "enter", "InlineFragment", 4 },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 4 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 1 },
				{ "enter", "OperationDefinition", 2 },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "IntValue", "value", "Argument" },
				{ "leave", "IntValue", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 2 },
				{ "enter", "OperationDefinition", 3 },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "VariableDefinition", 1 },
				{ "enter", "Variable", "variable", "VariableDefinition" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "variable", "VariableDefinition" },
				{ "enter", "NamedType", "type", "VariableDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "type", "VariableDefinition" },
				{ "leave", "VariableDefinition", 1 },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "enter", "Field", 2 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 2 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 3 },
				{ "enter", "FragmentDefinition", 4 },
				{ "enter", "Name", "name", "FragmentDefinition" },
				{ "leave", "Name", "name", "FragmentDefinition" },
				{ "enter", "NamedType", "typeCondition", "FragmentDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "typeCondition", "FragmentDefinition" },
				{ "enter", "Directive", 1 },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 1 },
				{ "enter", "SelectionSet", "selectionSet", "FragmentDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "Argument", 2 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 2 },
				{ "enter", "Argument", 3 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "ObjectValue", "value", "Argument" },
				{ "enter", "ObjectField", 1 },
				{ "enter", "Name", "name", "ObjectField" },
				{ "leave", "Name", "name", "ObjectField" },
				{ "enter", "StringValue", "value", "ObjectField" },
				{ "leave", "StringValue", "value", "ObjectField" },
				{ "leave", "ObjectField", 1 },
				{ "enter", "ObjectField", 2 },
				{ "enter", "Name", "name", "ObjectField" },
				{ "leave", "Name", "name", "ObjectField" },
				{ "enter", "StringValue", "value", "ObjectField" },
				{ "leave", "StringValue", "value", "ObjectField" },
				{ "leave", "ObjectField", 2 },
				{ "leave", "ObjectValue", "value", "Argument" },
				{ "leave", "Argument", 3 },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "FragmentDefinition" },
				{ "leave", "FragmentDefinition", 4 },
				{ "enter", "OperationDefinition", 5 },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 1 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "BooleanValue", "value", "Argument" },
				{ "leave", "BooleanValue", "value", "Argument" },
				{ "leave", "Argument", 1 },
				{ "enter", "Argument", 2 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "BooleanValue", "value", "Argument" },
				{ "leave", "BooleanValue", "value", "Argument" },
				{ "leave", "Argument", 2 },
				{ "enter", "Argument", 3 },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "NullValue", "value", "Argument" },
				{ "leave", "NullValue", "value", "Argument" },
				{ "leave", "Argument", 3 },
				{ "leave", "Field", 1 },
				{ "enter", "Field", 2 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 2 },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 5 },
				{ "enter", "OperationDefinition", 6 },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 1 },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1 },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 6 },
				{ "leave", "Document" },
			})
		end)

		describe("Support for custom AST nodes", function()
			local customAST = parse("{ a }")
			table.insert(customAST.definitions[1].selectionSet.selections, {
				kind = "CustomField",
				name = {
					kind = "Name",
					value = "b",
				},
				selectionSet = {
					kind = "SelectionSet",
					selections = {
						{
							kind = "CustomField",
							name = {
								kind = "Name",
								value = "c",
							},
						},
					},
				},
			})

			it("does not traverse unknown node kinds", function()
				local visited = {}
				visit(customAST, {
					enter = function(self, node)
						table.insert(visited, { "enter", node.kind, getValue(node) })
					end,
					leave = function(self, node)
						table.insert(visited, { "leave", node.kind, getValue(node) })
					end,
				})

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "CustomField" },
					{ "leave", "CustomField" },
					{ "leave", "SelectionSet" },
					{ "leave", "OperationDefinition" },
					{ "leave", "Document" },
				})
			end)

			it("does traverse unknown node kinds with visitor keys", function()
				local customQueryDocumentKeys = Object.assign({}, QueryDocumentKeys)
				customQueryDocumentKeys.CustomField = { "name", "selectionSet" }

				local visited = {}
				local visitor = {
					enter = function(self, node)
						table.insert(visited, { "enter", node.kind, getValue(node) })
					end,
					leave = function(self, node)
						table.insert(visited, { "leave", node.kind, getValue(node) })
					end,
				}
				visit(customAST, visitor, customQueryDocumentKeys)

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "CustomField" },
					{ "enter", "Name", "b" },
					{ "leave", "Name", "b" },
					{ "enter", "SelectionSet" },
					{ "enter", "CustomField" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "leave", "CustomField" },
					{ "leave", "SelectionSet" },
					{ "leave", "CustomField" },
					{ "leave", "SelectionSet" },
					{ "leave", "OperationDefinition" },
					{ "leave", "Document" },
				})
			end)
		end)

		describe("visitInParallel", function()
			-- // Note: nearly identical to the above test of the same test but
			-- // using visitInParallel.
			it("allows skipping a sub-tree", function()
				local visited = {}

				local ast = parse("{ a, b { x }, c }")
				visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "enter", node.kind, getValue(node) })
								if node.kind == "Field" and node.name.value == "b" then
									return false
								end
								return -- ROBLOX deviation: no implicit returns
							end,

							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "leave", node.kind, getValue(node) })
							end,
						},
					})
				)

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "leave", "Field" },
					{ "leave", "SelectionSet" },
					{ "leave", "OperationDefinition" },
					{ "leave", "Document" },
				})
			end)

			it("allows skipping different sub-trees", function()
				local visited = {}

				local ast = parse("{ a { x }, b { y} }")
				visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "no-a", "enter", node.kind, getValue(node) })
								if node.kind == "Field" and node.name.value == "a" then
									return false
								end
								return -- ROBLOX deviation: no implicit returns
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "no-a", "leave", node.kind, getValue(node) })
							end,
						},
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "no-b", "enter", node.kind, getValue(node) })
								if node.kind == "Field" and node.name.value == "b" then
									return false
								end
								return -- ROBLOX deviation: no implicit returns
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "no-b", "leave", node.kind, getValue(node) })
							end,
						},
					})
				)

				expect(visited).toEqual({
					{ "no-a", "enter", "Document" },
					{ "no-b", "enter", "Document" },
					{ "no-a", "enter", "OperationDefinition" },
					{ "no-b", "enter", "OperationDefinition" },
					{ "no-a", "enter", "SelectionSet" },
					{ "no-b", "enter", "SelectionSet" },
					{ "no-a", "enter", "Field" },
					{ "no-b", "enter", "Field" },
					{ "no-b", "enter", "Name", "a" },
					{ "no-b", "leave", "Name", "a" },
					{ "no-b", "enter", "SelectionSet" },
					{ "no-b", "enter", "Field" },
					{ "no-b", "enter", "Name", "x" },
					{ "no-b", "leave", "Name", "x" },
					{ "no-b", "leave", "Field" },
					{ "no-b", "leave", "SelectionSet" },
					{ "no-b", "leave", "Field" },
					{ "no-a", "enter", "Field" },
					{ "no-b", "enter", "Field" },
					{ "no-a", "enter", "Name", "b" },
					{ "no-a", "leave", "Name", "b" },
					{ "no-a", "enter", "SelectionSet" },
					{ "no-a", "enter", "Field" },
					{ "no-a", "enter", "Name", "y" },
					{ "no-a", "leave", "Name", "y" },
					{ "no-a", "leave", "Field" },
					{ "no-a", "leave", "SelectionSet" },
					{ "no-a", "leave", "Field" },
					{ "no-a", "leave", "SelectionSet" },
					{ "no-b", "leave", "SelectionSet" },
					{ "no-a", "leave", "OperationDefinition" },
					{ "no-b", "leave", "OperationDefinition" },
					{ "no-a", "leave", "Document" },
					{ "no-b", "leave", "Document" },
				})
			end)

			-- // Note: nearly identical to the above test of the same test but
			-- // using visitInParallel.
			it("allows early exit while visiting", function()
				local visited = {}

				local ast = parse("{ a, b { x }, c }")
				visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "enter", node.kind, getValue(node) })
								if node.kind == "Name" and node.value == "x" then
									return BREAK
								end
								return -- ROBLOX deviation: no implicit returns
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "leave", node.kind, getValue(node) })
							end,
						},
					})
				)

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "b" },
					{ "leave", "Name", "b" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "x" },
				})
			end)

			it("allows early exit from different points", function()
				local visited = {}

				local ast = parse("{ a { y }, b { x } }")
				visit(
					ast,
					visitInParallel(
						{
							{
								enter = function(self, ...)
									local node = ...
									checkVisitorFnArgs(expect, ast, { ... })
									table.insert(visited, { "break-a", "enter", node.kind, getValue(node) })
									if node.kind == "Name" and node.value == "a" then
										return BREAK
									end
									return -- ROBLOX deviation: no implicit returns
								end,
								-- istanbul ignore next (Never called and used as a placeholder)
								leave = function()
									invariant(false)
								end,
							},
							{
								enter = function(self, ...)
									local node = ...
									checkVisitorFnArgs(expect, ast, { ... })
									table.insert(visited, { "break-b", "enter", node.kind, getValue(node) })
									if node.kind == "Name" and node.value == "b" then
										return BREAK
									end
									return -- ROBLOX deviation: no implicit returns
								end,
								leave = function(self, ...)
									local node = ...
									checkVisitorFnArgs(expect, ast, { ... })
									table.insert(visited, { "break-b", "leave", node.kind, getValue(node) })
								end,
							},
						}
					)
				)

				expect(visited).toEqual({
					{ "break-a", "enter", "Document" },
					{ "break-b", "enter", "Document" },
					{ "break-a", "enter", "OperationDefinition" },
					{ "break-b", "enter", "OperationDefinition" },
					{ "break-a", "enter", "SelectionSet" },
					{ "break-b", "enter", "SelectionSet" },
					{ "break-a", "enter", "Field" },
					{ "break-b", "enter", "Field" },
					{ "break-a", "enter", "Name", "a" },
					{ "break-b", "enter", "Name", "a" },
					{ "break-b", "leave", "Name", "a" },
					{ "break-b", "enter", "SelectionSet" },
					{ "break-b", "enter", "Field" },
					{ "break-b", "enter", "Name", "y" },
					{ "break-b", "leave", "Name", "y" },
					{ "break-b", "leave", "Field" },
					{ "break-b", "leave", "SelectionSet" },
					{ "break-b", "leave", "Field" },
					{ "break-b", "enter", "Field" },
					{ "break-b", "enter", "Name", "b" },
				})
			end)

			-- // Note: nearly identical to the above test of the same test but
			-- // using visitInParallel.
			it("allows early exit while leaving", function()
				local visited = {}

				local ast = parse("{ a, b { x }, c }")
				visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "enter", node.kind, getValue(node) })
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "leave", node.kind, getValue(node) })
								if node.kind == "Name" and node.value == "x" then
									return BREAK
								end
								return -- ROBLOX deviation: no implicit returns
							end,
						},
					})
				)

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "b" },
					{ "leave", "Name", "b" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "x" },
					{ "leave", "Name", "x" },
				})
			end)

			it("allows early exit from leaving different points", function()
				local visited = {}

				local ast = parse("{ a { y }, b { x } }")
				visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "break-a", "enter", node.kind, getValue(node) })
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "break-a", "leave", node.kind, getValue(node) })
								if node.kind == "Field" and node.name.value == "a" then
									return BREAK
								end
								return -- ROBLOX deviation: no implicit returns
							end,
						},
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "break-b", "enter", node.kind, getValue(node) })
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "break-b", "leave", node.kind, getValue(node) })
								if node.kind == "Field" and node.name.value == "b" then
									return BREAK
								end
								return -- ROBLOX deviation: no implicit returns
							end,
						},
					})
				)

				expect(visited).toEqual({
					{ "break-a", "enter", "Document" },
					{ "break-b", "enter", "Document" },
					{ "break-a", "enter", "OperationDefinition" },
					{ "break-b", "enter", "OperationDefinition" },
					{ "break-a", "enter", "SelectionSet" },
					{ "break-b", "enter", "SelectionSet" },
					{ "break-a", "enter", "Field" },
					{ "break-b", "enter", "Field" },
					{ "break-a", "enter", "Name", "a" },
					{ "break-b", "enter", "Name", "a" },
					{ "break-a", "leave", "Name", "a" },
					{ "break-b", "leave", "Name", "a" },
					{ "break-a", "enter", "SelectionSet" },
					{ "break-b", "enter", "SelectionSet" },
					{ "break-a", "enter", "Field" },
					{ "break-b", "enter", "Field" },
					{ "break-a", "enter", "Name", "y" },
					{ "break-b", "enter", "Name", "y" },
					{ "break-a", "leave", "Name", "y" },
					{ "break-b", "leave", "Name", "y" },
					{ "break-a", "leave", "Field" },
					{ "break-b", "leave", "Field" },
					{ "break-a", "leave", "SelectionSet" },
					{ "break-b", "leave", "SelectionSet" },
					{ "break-a", "leave", "Field" },
					{ "break-b", "leave", "Field" },
					{ "break-b", "enter", "Field" },
					{ "break-b", "enter", "Name", "b" },
					{ "break-b", "leave", "Name", "b" },
					{ "break-b", "enter", "SelectionSet" },
					{ "break-b", "enter", "Field" },
					{ "break-b", "enter", "Name", "x" },
					{ "break-b", "leave", "Name", "x" },
					{ "break-b", "leave", "Field" },
					{ "break-b", "leave", "SelectionSet" },
					{ "break-b", "leave", "Field" },
				})
			end)

			it("allows for editing on enter", function()
				local visited = {}

				local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })
				local editedAST = visit(
					ast,
					visitInParallel({
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								if node.kind == "Field" and node.name.value == "b" then
									return NULL
								end
								return -- ROBLOX deviation: no implicit returns
							end,
						},
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "enter", node.kind, getValue(node) })
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(
									expect,
									ast,
									{ ... },
									true --[[ isEdited ]]
								)
								table.insert(visited, { "leave", node.kind, getValue(node) })
							end,
						},
					})
				)

				expect(ast).toEqual(parse("{ a, b, c { a, b, c } }", { noLocation = true }))

				expect(editedAST).toEqual(parse("{ a,    c { a,    c } }", { noLocation = true }))

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "leave", "Field" },
					{ "leave", "SelectionSet" },
					{ "leave", "Field" },
					{ "leave", "SelectionSet" },
					{ "leave", "OperationDefinition" },
					{ "leave", "Document" },
				})
			end)

			it("allows for editing on leave", function()
				local visited = {}

				local ast = parse("{ a, b, c { a, b, c } }", { noLocation = true })
				local editedAST = visit(
					ast,
					visitInParallel({
						{
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(
									expect,
									ast,
									{ ... },
									true --[[ isEdited ]]
								)
								if node.kind == "Field" and node.name.value == "b" then
									return NULL
								end
								return -- ROBLOX deviation: no implicit returns
							end,
						},
						{
							enter = function(self, ...)
								local node = ...
								checkVisitorFnArgs(expect, ast, { ... })
								table.insert(visited, { "enter", node.kind, getValue(node) })
							end,
							leave = function(self, ...)
								local node = ...
								checkVisitorFnArgs(
									expect,
									ast,
									{ ... },--[[ isEdited ]]
									true
								)
								table.insert(visited, { "leave", node.kind, getValue(node) })
							end,
						},
					})
				)

				expect(ast).toEqual(parse("{ a, b, c { a, b, c } }", { noLocation = true }))

				expect(editedAST).toEqual(parse("{ a,    c { a,    c } }", { noLocation = true }))

				expect(visited).toEqual({
					{ "enter", "Document" },
					{ "enter", "OperationDefinition" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "b" },
					{ "leave", "Name", "b" },
					{ "enter", "Field" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "enter", "SelectionSet" },
					{ "enter", "Field" },
					{ "enter", "Name", "a" },
					{ "leave", "Name", "a" },
					{ "leave", "Field" },
					{ "enter", "Field" },
					{ "enter", "Name", "b" },
					{ "leave", "Name", "b" },
					{ "enter", "Field" },
					{ "enter", "Name", "c" },
					{ "leave", "Name", "c" },
					{ "leave", "Field" },
					{ "leave", "SelectionSet" },
					{ "leave", "Field" },
					{ "leave", "SelectionSet" },
					{ "leave", "OperationDefinition" },
					{ "leave", "Document" },
				})
			end)
        end)
	end)
end
