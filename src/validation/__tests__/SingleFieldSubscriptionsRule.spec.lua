-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/bbd8429b85594d9ee8cc632436e2d0f900d703ef/src/validation/__tests__/SingleFieldSubscriptionsRule-test.js

return function()
	local validationWorkspace = script.Parent.Parent
	local SingleFieldSubscriptionsRule = require(validationWorkspace.rules.SingleFieldSubscriptionsRule)
		.SingleFieldSubscriptionsRule
	local harness = require(script.Parent.harness)
	local expectValidationErrors = harness.expectValidationErrors

	local function expectErrors(expect_, queryStr: string)
		-- ROBLOX deviation: we append a new line at the begining of the
		-- query string because of how Lua multiline strings works (it does
		-- take the new line if it's the first character of the string)
		return expectValidationErrors(expect_, SingleFieldSubscriptionsRule, "\n" .. queryStr)
	end

	local function expectValid(expect_, queryStr: string)
		expectErrors(expect_, queryStr).toEqual({})
	end

	describe("Validate: Subscriptions with single field", function()
		it("valid subscription", function()
			expectValid(expect, [[
				subscription ImportantEmails {
					importantEmails
				}
			]])
		end)

		itSKIP("fails with more than one root field", function()
			-- ROBLOX FIXME: location is not quite exact
			expectErrors(expect, [[
      subscription ImportantEmails {
        importantEmails
        notImportantEmails
      }
			]]).toEqual({
				{
					message = 'Subscription "ImportantEmails" must select only one top level field.',
					locations = {{ line = 4, column = 9 }},
				},
			})
		end)

		itSKIP("fails with more than one root field including introspection", function()
			-- ROBLOX FIXME: location is not quite exact
			expectErrors(expect, [[
      subscription ImportantEmails {
        importantEmails
        __typename
      }
			]]).toEqual({
				{
					message = 'Subscription "ImportantEmails" must select only one top level field.',
					locations = {{ line = 4, column = 9 }},
				},
			})
		end)

		itSKIP("fails with many more than one root field", function()
			-- ROBLOX FIXME: location is not quite exact
			expectErrors(expect, [[
      subscription ImportantEmails {
        importantEmails
        notImportantEmails
        spamEmails
      }
			]]).toEqual({
				{
					message = 'Subscription "ImportantEmails" must select only one top level field.',
					locations = {
						{ line = 4, column = 9 },
						{ line = 5, column = 9 },
					},
				},
			})
		end)

		itSKIP("fails with more than one root field in anonymous subscriptions", function()
			-- ROBLOX FIXME: location is not quite exact
			expectErrors(expect, [[
      subscription {
        importantEmails
        notImportantEmails
      }
			]]).toEqual({
				{
					message = "Anonymous Subscription must select only one top level field.",
					locations = {{ line = 4, column = 9 }},
				},
			})
		end)
	end)
end
