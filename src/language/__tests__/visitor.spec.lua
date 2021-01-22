-- upstream https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/visitor-test.js

return function()
	local srcWorkspace = script.Parent.Parent.Parent
	local root = srcWorkspace.Parent
	local LuauPolyfill = require(root.Packages.LuauPolyfill)
	local UtilArray = require(srcWorkspace.luaUtils.Array)
	local Array = LuauPolyfill.Array
	local Object = LuauPolyfill.Object

	local Kind = require(script.Parent.Parent.kinds).Kind
	local parse = require(script.Parent.Parent.parser).parse
	local visitor = require(script.Parent.Parent.visitor)
	local visit = visitor.visit
	local BREAK = visitor.BREAK
	local REMOVE = visitor.REMOVE
	local kitchenSinkQuery = require(srcWorkspace.__fixtures__).kitchenSinkQuery

	-- local devPrint = require(script.Parent.Parent.Parent.TestMatchers.devPrint)

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
							{ ... },--[[ isEdited ]]
							true
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
							{ ... },--[[ isEdited ]]
							true
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
						return REMOVE -- ROBLOX deviation: returning REMOVE instead of null in JS to distinguish between undefined
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
						{ ... },--[[ isEdited ]]
						true
					)
					if node.kind == "Field" and node.name.value == "b" then
						return REMOVE -- ROBLOX deviation: returning REMOVE instead of null in JS to distinguish between undefined
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
						{ ... },--[[ isEdited ]]
						true
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
				{ "enter", "Document", nil },
				{ "enter", "OperationDefinition", nil },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field", nil },
				{ "enter", "Field", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "c" },
				{ "leave", "Name", "c" },
				{ "leave", "Field", nil },
				{ "leave", "SelectionSet", nil },
				{ "leave", "OperationDefinition", nil },
				{ "leave", "Document", nil },
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
				{ "enter", "Document", nil },
				{ "enter", "OperationDefinition", nil },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "b" },
				{ "leave", "Name", "b" },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
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
				{ "enter", "Document", nil },
				{ "enter", "OperationDefinition", nil },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "leave", "Field", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "b" },
				{ "leave", "Name", "b" },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
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
				{ "enter", "SelectionSet", nil },
				{ "enter", "Name", "a" },
				{ "enter", "Name", "b" },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Name", "x" },
				{ "leave", "SelectionSet", nil },
				{ "enter", "Name", "c" },
				{ "leave", "SelectionSet", nil },
			})
		end)

		-- Parser.parseVariableDefinition not implemented yet
		itSKIP("Experimental: visits variables defined in fragments", function()
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
				{ "enter", "Document", nil },
				{ "enter", "FragmentDefinition", nil },
				{ "enter", "Name", "a" },
				{ "leave", "Name", "a" },
				{ "enter", "VariableDefinition", nil },
				{ "enter", "Variable", nil },
				{ "enter", "Name", "v" },
				{ "leave", "Name", "v" },
				{ "leave", "Variable", nil },
				{ "enter", "NamedType", nil },
				{ "enter", "Name", "Boolean" },
				{ "leave", "Name", "Boolean" },
				{ "leave", "NamedType", nil },
				{ "enter", "BooleanValue", false },
				{ "leave", "BooleanValue", false },
				{ "leave", "VariableDefinition", nil },
				{ "enter", "NamedType", nil },
				{ "enter", "Name", "t" },
				{ "leave", "Name", "t" },
				{ "leave", "NamedType", nil },
				{ "enter", "SelectionSet", nil },
				{ "enter", "Field", nil },
				{ "enter", "Name", "f" },
				{ "leave", "Name", "f" },
				{ "leave", "Field", nil },
				{ "leave", "SelectionSet", nil },
				{ "leave", "FragmentDefinition", nil },
				{ "leave", "Document", nil },
			})
		end)

		-- Parser.parseVariableDefinition not implemented yet
		itSKIP("visits kitchen sink", function()
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
					visited.push()

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
				{ "enter", "Document", nil, nil },
				{ "enter", "OperationDefinition", 0, nil },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "VariableDefinition", 0, nil },
				{ "enter", "Variable", "variable", "VariableDefinition" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "variable", "VariableDefinition" },
				{ "enter", "NamedType", "type", "VariableDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "type", "VariableDefinition" },
				{ "leave", "VariableDefinition", 0, nil },
				{ "enter", "VariableDefinition", 1, nil },
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
				{ "leave", "VariableDefinition", 1, nil },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "alias", "Field" },
				{ "leave", "Name", "alias", "Field" },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "ListValue", "value", "Argument" },
				{ "enter", "IntValue", 0, nil },
				{ "leave", "IntValue", 0, nil },
				{ "enter", "IntValue", 1, nil },
				{ "leave", "IntValue", 1, nil },
				{ "leave", "ListValue", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "enter", "InlineFragment", 1, nil },
				{ "enter", "NamedType", "typeCondition", "InlineFragment" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "typeCondition", "InlineFragment" },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "enter", "Field", 1, nil },
				{ "enter", "Name", "alias", "Field" },
				{ "leave", "Name", "alias", "Field" },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "IntValue", "value", "Argument" },
				{ "leave", "IntValue", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "Argument", 1, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1, nil },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "enter", "FragmentSpread", 1, nil },
				{ "enter", "Name", "name", "FragmentSpread" },
				{ "leave", "Name", "name", "FragmentSpread" },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "leave", "FragmentSpread", 1, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 1, nil },
				{ "enter", "InlineFragment", 2, nil },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 2, nil },
				{ "enter", "InlineFragment", 3, nil },
				{ "enter", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "InlineFragment" },
				{ "leave", "InlineFragment", 3, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 0, nil },
				{ "enter", "OperationDefinition", 1, nil },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "IntValue", "value", "Argument" },
				{ "leave", "IntValue", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 1, nil },
				{ "enter", "OperationDefinition", 2, nil },
				{ "enter", "Name", "name", "OperationDefinition" },
				{ "leave", "Name", "name", "OperationDefinition" },
				{ "enter", "VariableDefinition", 0, nil },
				{ "enter", "Variable", "variable", "VariableDefinition" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "variable", "VariableDefinition" },
				{ "enter", "NamedType", "type", "VariableDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "type", "VariableDefinition" },
				{ "leave", "VariableDefinition", 0, nil },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "enter", "Field", 1, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "SelectionSet", "selectionSet", "Field" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 1, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 2, nil },
				{ "enter", "FragmentDefinition", 3, nil },
				{ "enter", "Name", "name", "FragmentDefinition" },
				{ "leave", "Name", "name", "FragmentDefinition" },
				{ "enter", "NamedType", "typeCondition", "FragmentDefinition" },
				{ "enter", "Name", "name", "NamedType" },
				{ "leave", "Name", "name", "NamedType" },
				{ "leave", "NamedType", "typeCondition", "FragmentDefinition" },
				{ "enter", "Directive", 0, nil },
				{ "enter", "Name", "name", "Directive" },
				{ "leave", "Name", "name", "Directive" },
				{ "leave", "Directive", 0, nil },
				{ "enter", "SelectionSet", "selectionSet", "FragmentDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "Argument", 1, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "Variable", "value", "Argument" },
				{ "enter", "Name", "name", "Variable" },
				{ "leave", "Name", "name", "Variable" },
				{ "leave", "Variable", "value", "Argument" },
				{ "leave", "Argument", 1, nil },
				{ "enter", "Argument", 2, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "ObjectValue", "value", "Argument" },
				{ "enter", "ObjectField", 0, nil },
				{ "enter", "Name", "name", "ObjectField" },
				{ "leave", "Name", "name", "ObjectField" },
				{ "enter", "StringValue", "value", "ObjectField" },
				{ "leave", "StringValue", "value", "ObjectField" },
				{ "leave", "ObjectField", 0, nil },
				{ "enter", "ObjectField", 1, nil },
				{ "enter", "Name", "name", "ObjectField" },
				{ "leave", "Name", "name", "ObjectField" },
				{ "enter", "StringValue", "value", "ObjectField" },
				{ "leave", "StringValue", "value", "ObjectField" },
				{ "leave", "ObjectField", 1, nil },
				{ "leave", "ObjectValue", "value", "Argument" },
				{ "leave", "Argument", 2, nil },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "FragmentDefinition" },
				{ "leave", "FragmentDefinition", 3, nil },
				{ "enter", "OperationDefinition", 4, nil },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "enter", "Argument", 0, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "BooleanValue", "value", "Argument" },
				{ "leave", "BooleanValue", "value", "Argument" },
				{ "leave", "Argument", 0, nil },
				{ "enter", "Argument", 1, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "BooleanValue", "value", "Argument" },
				{ "leave", "BooleanValue", "value", "Argument" },
				{ "leave", "Argument", 1, nil },
				{ "enter", "Argument", 2, nil },
				{ "enter", "Name", "name", "Argument" },
				{ "leave", "Name", "name", "Argument" },
				{ "enter", "NullValue", "value", "Argument" },
				{ "leave", "NullValue", "value", "Argument" },
				{ "leave", "Argument", 2, nil },
				{ "leave", "Field", 0, nil },
				{ "enter", "Field", 1, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 1, nil },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 4, nil },
				{ "enter", "OperationDefinition", 5, nil },
				{ "enter", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "enter", "Field", 0, nil },
				{ "enter", "Name", "name", "Field" },
				{ "leave", "Name", "name", "Field" },
				{ "leave", "Field", 0, nil },
				{ "leave", "SelectionSet", "selectionSet", "OperationDefinition" },
				{ "leave", "OperationDefinition", 5, nil },
				{ "leave", "Document", nil, nil },
			})
		end)
	end)
end
