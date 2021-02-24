return function()
	local Map = require(script.Parent.Parent.Map)
	local instanceOf = require(script.Parent.Parent.Parent.jsutils.instanceOf)

	local AN_ITEM = "bar"
	local ANOTHER_ITEM = "baz"

	describe("Map", function()

		describe("constructors", function()
			it("creates an empty array", function()
				local foo = Map.new()
				expect(foo.size).to.equal(0)
			end)

			it("creates a Map from an array", function()
				local foo = Map.new({
					{ AN_ITEM, "foo" },
					{ ANOTHER_ITEM, "val" },
				})
				expect(foo.size).to.equal(2)
				expect(foo:has(AN_ITEM)).to.equal(true)
				expect(foo:has(ANOTHER_ITEM)).to.equal(true)
			end)

			it("creates a Map from an array with duplicate keys", function()
				local foo = Map.new({
					{ AN_ITEM, "foo1" },
					{ AN_ITEM, "foo2" },
				})
				expect(foo.size).to.equal(1)
				expect(foo:get(AN_ITEM)).to.equal("foo2")

				expect(foo:keys()).toEqual({ AN_ITEM })
				expect(foo:values()).toEqual({ "foo2" })
				expect(foo:entries()).toEqual({ { AN_ITEM, "foo2" } })
			end)

			it("preserves the order of keys first assignment", function()
				local foo = Map.new({
					{ AN_ITEM, "foo1" },
					{ ANOTHER_ITEM, "bar" },
					{ AN_ITEM, "foo2" },
				})
				expect(foo.size).to.equal(2)
				expect(foo:get(AN_ITEM)).to.equal("foo2")
				expect(foo:get(ANOTHER_ITEM)).to.equal("bar")

				expect(foo:keys()).toEqual({ AN_ITEM, ANOTHER_ITEM })
				expect(foo:values()).toEqual({ "foo2", "bar" })
				expect(foo:entries()).toEqual({ { AN_ITEM, "foo2" }, { ANOTHER_ITEM, "bar" } })
			end)

			it("throws when trying to create a set from a non-iterable", function()
				expect(function()
					return Map.new(true)
				end).to.throw("cannot create array from value of type `boolean`")
				expect(function()
					return Map.new(1)
				end).to.throw("cannot create array from value of type `number`")
			end)

		end)

		describe("type", function()
			it("instanceOf return true for an actual Map object", function()
				local foo = Map.new()
				expect(instanceOf(foo, Map)).to.equal(true)
			end)

			it("instanceOf return false for an regular plain object", function()
				local foo = {}
				expect(instanceOf(foo, Map)).to.equal(false)
			end)
		end)

		describe("set", function()
			it("returns the Map object", function()
				local foo = Map.new()
				expect(foo:set(1)).to.equal(foo)
			end)

			it("increments the size if the element is added for the first time", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				expect(foo.size).to.equal(1)
			end)

			it("does not increment the size the second time an element is added", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:set(AN_ITEM, "val")
				expect(foo.size).to.equal(1)
			end)

			it("sets values correctly to true/false", function()
				local foo = Map.new({{ AN_ITEM, false }})
				foo:set(AN_ITEM, false)
				expect(foo.size).to.equal(1)
				expect(foo:get(AN_ITEM)).to.equal(false)

				foo:set(AN_ITEM, true)
				expect(foo.size).to.equal(1)
				expect(foo:get(AN_ITEM)).to.equal(true)

				foo:set(AN_ITEM, false)
				expect(foo.size).to.equal(1)
				expect(foo:get(AN_ITEM)).to.equal(false)
			end)
		end)

		describe("get", function()
			it("returns value of item from provided key", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				expect(foo:get(AN_ITEM)).to.equal("foo")
			end)

			it("returns nil if the item is not in the Map", function()
				local foo = Map.new()
				expect(foo:get(AN_ITEM)).to.equal(nil)
			end)

		end)

		describe("clear", function()
			it("sets the size to zero", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:clear()
				expect(foo.size).to.equal(0)
			end)

			it("removes the items from the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:clear()
				expect(foo:has(AN_ITEM)).to.equal(false)
			end)
		end)

		describe("delete", function()
			it("removes the items from the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:delete(AN_ITEM)
				expect(foo:has(AN_ITEM)).to.equal(false)
			end)

			it("returns true if the item was in the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				expect(foo:delete(AN_ITEM)).to.equal(true)
			end)

			it("returns false if the item was not in the Map", function()
				local foo = Map.new()
				expect(foo:delete(AN_ITEM)).to.equal(false)
			end)

			it("decrements the size if the item was in the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:delete(AN_ITEM)
				expect(foo.size).to.equal(0)
			end)

			it("does not decrement the size if the item was not in the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:delete(ANOTHER_ITEM)
				expect(foo.size).to.equal(1)
			end)

			it("deletes value set to false", function()
				local foo = Map.new({ { AN_ITEM, false } })

				foo:delete(AN_ITEM)

				expect(foo.size).to.equal(0)
				expect(foo:get(AN_ITEM)).to.equal(nil)
			end)
		end)

		describe("has", function()
			it("returns true if the item is in the Map", function()
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				expect(foo:has(AN_ITEM)).to.equal(true)
			end)

			it("returns false if the item is not in the Map", function()
				local foo = Map.new()
				expect(foo:has(AN_ITEM)).to.equal(false)
			end)

			it("returns correctly with value set to false", function()
				local foo = Map.new({ { AN_ITEM, false } })

				expect(foo:has(AN_ITEM)).to.equal(true)
			end)
		end)

		describe("keys / values / entries", function()
			it("returns array of elements", function()
				local myMap = Map.new()
				myMap:set(AN_ITEM, "foo")
				myMap:set(ANOTHER_ITEM, "val")

				expect(myMap:keys()).toEqual({ AN_ITEM, ANOTHER_ITEM })
				expect(myMap:values()).toEqual({ "foo", "val" })
				expect(myMap:entries()).toEqual({
					{ AN_ITEM, "foo" },
					{ ANOTHER_ITEM, "val" },
				})
			end)
		end)

		describe("__index", function()
			it("can access fields directly without using get", function()
				local typeName = "size"

				local foo = Map.new({
					{ AN_ITEM, "foo" },
					{ ANOTHER_ITEM, "val" },
					{ typeName, "buzz" },
				})
				expect(foo.size).to.equal(3)
				expect(foo[AN_ITEM]).to.equal("foo")
				expect(foo[ANOTHER_ITEM]).to.equal("val")
				expect(foo:get(typeName)).to.equal("buzz")
			end)
		end)

		describe("__newindex", function()
			it("can set fields directly without using set", function()
				local foo = Map.new()

				expect(foo.size).to.equal(0)

				foo[AN_ITEM] = "foo"
				foo[ANOTHER_ITEM] = "val"
				foo.fizz = "buzz"

				expect(foo.size).to.equal(3)
				expect(foo:get(AN_ITEM)).to.equal("foo")
				expect(foo:get(ANOTHER_ITEM)).to.equal("val")
				expect(foo:get("fizz")).to.equal("buzz")
			end)
		end)

		describe("ipairs", function()

			local function makeArray(...)
				local array = {}
				for _, item in ... do
					table.insert(array, item)
				end
				return array
			end

			it("iterates on an empty set", function()
				local expect: any = expect
				local foo = Map.new()
				expect(makeArray(foo:ipairs())).toEqual({})
			end)

			it("iterates on the elements by their insertion order", function()
				local expect: any = expect
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:set(ANOTHER_ITEM, "val")
				expect(makeArray(foo:ipairs())).toEqual({
					{ AN_ITEM, "foo" },
					{ ANOTHER_ITEM, "val" },
				})
			end)

			it("does not iterate on removed elements", function()
				local expect: any = expect
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:set(ANOTHER_ITEM, "val")
				foo:delete(AN_ITEM)
				expect(makeArray(foo:ipairs())).toEqual({ { ANOTHER_ITEM, "val" } })
			end)

			it("iterates on elements if the added back to the Map", function()
				local expect: any = expect
				local foo = Map.new()
				foo:set(AN_ITEM, "foo")
				foo:set(ANOTHER_ITEM, "val")
				foo:delete(AN_ITEM)
				foo:set(AN_ITEM, "food")
				expect(makeArray(foo:ipairs())).toEqual({
					{ ANOTHER_ITEM, "val" },
					{ AN_ITEM, "food" },
				})
			end)
		end)


		describe("Integration Tests", function()
			-- the following tests are adapted from the examples shown on the MDN documentation:
			-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map#examples
			it("MDN Examples", function()
				local myMap = Map.new()

				local keyString = "a string"
				local keyObj = {}
				local keyFunc = function()
				end

				-- setting the values
				myMap:set(keyString, "value associated with 'a string'")
				myMap:set(keyObj, "value associated with keyObj")
				myMap:set(keyFunc, "value associated with keyFunc")

				expect(myMap.size).to.equal(3)

				-- getting the values
				expect(myMap:get(keyString)).to.equal("value associated with 'a string'")
				expect(myMap:get(keyObj)).to.equal("value associated with keyObj")
				expect(myMap:get(keyFunc)).to.equal("value associated with keyFunc")

				expect(myMap:get("a string")).to.equal("value associated with 'a string'")

				expect(myMap:get({})).to.equal(nil) -- nil, because keyObj !== {}
				expect(myMap:get(function() -- nil because keyFunc !== function () {}
				end)).to.equal(nil)
			end)

			it("handles non-traditional keys", function()
				local myMap = Map.new()

				local falseKey = false
				local trueKey = true
				local negativeKey = -1
				local emptyKey = ""

				myMap:set(falseKey, "apple")
				myMap:set(trueKey, "bear")
				myMap:set(negativeKey, "corgi")
				myMap:set(emptyKey, "doge")

				expect(myMap.size).to.equal(4)

				expect(myMap:get(falseKey)).to.equal("apple")
				expect(myMap:get(trueKey)).to.equal("bear")
				expect(myMap:get(negativeKey)).to.equal("corgi")
				expect(myMap:get(emptyKey)).to.equal("doge")

			end)

		end)
	end)
end
