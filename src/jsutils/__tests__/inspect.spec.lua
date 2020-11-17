-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/__tests__/inspect-test.js
return function()
	local jsutils = script.Parent.Parent
	local inspect = require(jsutils.inspect)
	local invariant = require(jsutils.invariant)
	local nodejsCustomInspectSymbol = require(jsutils.nodejsCustomInspectSymbol)

	describe("inspect", function()
		-- it("undefined", function()
		-- 	expect(inspect(nil)).to.equal("undefined")
		-- end)

		it("null", function()
			expect(inspect(nil)).to.equal("nil")
		end)

		it("boolean", function()
			expect(inspect(true)).to.equal("true")
			expect(inspect(false)).to.equal("false")
		end)

		it("string", function()
			expect(inspect("")).to.equal('""')
			expect(inspect("abc")).to.equal('"abc"')
			expect(inspect('"')).to.equal('"\\""')
		end)

		it("number", function()
			expect(inspect(0)).to.equal("0")
			expect(inspect(3.14)).to.equal("3.14")
			expect(inspect(0/0)).to.equal("NaN")
			expect(inspect(math.huge)).to.equal("Infinity")
			expect(inspect(-math.huge)).to.equal("-Infinity")
		end)

		it("function", function()
			local unnamedFuncStr = inspect(function()
				return invariant(false)
			end)

			expect(unnamedFuncStr).to.equal("[function]")

			-- deviation: cannot get a function's name in Lua
			-- local function namedFunc()
			-- 	invariant(false)
			-- end

			-- expect(inspect(namedFunc)).to.equal("[function namedFunc]")
		end)

		it("array", function()
			expect(inspect({})).to.equal("[]")
			-- deviation: Lua does not handle nil elements
			expect(inspect({true})).to.equal("[true]")
			expect(inspect({1, 0/0})).to.equal("[1, NaN]")
			expect(inspect({{"a", "b"}, "c"})).to.equal('[["a", "b"], "c"]')

			expect(inspect({{{}}})).to.equal("[[[]]]")
			expect(inspect({{{"a"}}})).to.equal("[[[Array]]]")
			expect(inspect({0, 1, 2, 3, 4, 5, 6, 7, 8, 9})).to.equal(
				"[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"
			)

			expect(inspect({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10})).to.equal(
				"[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ... 1 more item]"
			)

			expect(inspect({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,})).to.equal(
				"[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ... 2 more items]"
			)
		end)

		it("object", function()
			-- deviation: an empty table is considered an empty array
			-- expect(inspect({})).to.equal("{}")
			expect(inspect({ a = 1 })).to.equal("{ a: 1 }")
			expect(inspect({ a = 1, b = 2 })).to.equal("{ a: 1, b: 2 }")
			-- deviation: avoid sparse array
			expect(inspect({ array = {false, 0} })).to.equal("{ array: [false, 0] }")

			expect(inspect({ a = { b = {} } })).to.equal("{ a: { b: [] } }")
			expect(inspect({ a = { b = { c = 1 } } })).to.equal("{ a: { b: [Object] } }")

			-- deviation:
			-- local map = Object.create(nil)
			-- map.a = true
			-- map.b = nil
			-- expect(inspect(map)).to.equal("{ a: true, b: null }")
		end)

		it("custom inspect", function()
			local object = {
				inspect = function()
					return"<custom inspect>"
				end,
			}

			expect(inspect(object)).to.equal("<custom inspect>")
		end)

		it("custom inspect that return `this` should work", function()
			local object = {}
			object.inspect = function()
				return object
			end

			expect(inspect(object)).to.equal("{ inspect: [function] }")
		end)

		it("custom symbol inspect is take precedence", function()
			local object = {
				inspect = function()
					invariant(false)
				end,
				[nodejsCustomInspectSymbol] = function()
					return"<custom symbol inspect>"
				end,
			}

			expect(inspect(object)).to.equal("<custom symbol inspect>")
		end)

		it("custom inspect returning object values", function()
			local object = {
				inspect = function()
					return {
						custom = "inspect",
					}
				end,
			}

			expect(inspect(object)).to.equal('{ custom: "inspect" }')
		end)

		it("custom inspect function that uses this", function()
			local object = {
				str = "Hello World!",
			}
			function object.inspect()
				return object.str
			end

			expect(inspect(object)).to.equal("Hello World!")
		end)

		it("detect circular objects", function()
			local obj = {}

			obj.self = obj
			obj.deepSelf = {self = obj}

			expect(inspect(obj)).to.equal("{ self: [Circular], deepSelf: { self: [Circular] } }")

			local array = {}

			array[1] = array
			array[2] = {array}

			expect(inspect(array)).to.equal("[[Circular], [[Circular]]]")

			local mixed = {array = {}}

			mixed.array[1] = mixed

			expect(inspect(mixed)).to.equal("{ array: [[Circular]] }")

			local customB
			local customA = {
				inspect = function()
					return customB
				end,
			}
			customB = {
				inspect = function()
					return customA
				end,
			}

			expect(inspect(customA)).to.equal("[Circular]")
		end)

		-- it("Use class names for the short form of an object", () => {
		-- 	class Foo {
		-- 		foo: string

		-- 		constructor() {
		-- 			this.foo = "bar"
		-- 		}
		-- 	}

		-- 	expect(inspect({{new Foo()}})).to.equal("[[[Foo]]]")

		-- 	(Foo.prototype: any)[Symbol.toStringTag] = "Bar"
		-- 	expect(inspect({{new Foo()}})).to.equal("[[[Bar]]]")

		-- 	local objectWithoutClassName = new (function () {
		-- 	this.foo = 1
		-- 	})()
		-- 	expect(inspect({{objectWithoutClassName}})).to.equal("[[[Object]]]")
		-- end)
	end)
end
