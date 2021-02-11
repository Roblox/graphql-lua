return function()
	local validationWorkspace = script.Parent.Parent
	local root = validationWorkspace.Parent
	local GraphQLError = require(root.error.GraphQLError).GraphQLError
	local parser = require(root.language.parser)
	local parse = parser.parse
	local utilities = root.utilities
	local TypeInfo = require(utilities.TypeInfo).TypeInfo
	local buildASTSchema = require(utilities.buildASTSchema)
	local buildSchema = buildASTSchema.buildSchema
	local validate = require(validationWorkspace.validate).validate
	local harness = require(script.Parent.harness)
	local testSchema = harness.testSchema
	local PackageWorkspace = root.Parent.Packages
	local Error = require(root.luaUtils.Error)
	local LuauPolyfill = require(PackageWorkspace.LuauPolyfill)
	local Array = LuauPolyfill.Array

	describe("Validate: Supports full validation", function()
		it("rejects invalid documents", function()
			expect(function()
				return validate(testSchema, nil)
			end).to.throw("Must provide document.")
		end)

		itSKIP("validates queries", function()
			local expect: any = expect
			local doc = parse([[
				query {
					catOrDog {
						... on Cat {
							furColor
						}
						... on Dog {
							isHouseTrained
						}
					}
				}
			]])

			local errors = validate(testSchema, doc)
			expect(errors).toEqual({})
		end)

		itSKIP("detects unknown fields", function()
			local expect: any = expect
			local doc = parse([[
      {
        unknown
      }
			]])

			local errors = validate(testSchema, doc)
			expect(errors).toEqual({
				{
					locations = {{ line = 3, column = 9 }},
					message = 'Cannot query field "unknown" on type "QueryRoot".',
				},
			})
		end)

		-- // NOTE: experimental
		itSKIP("validates using a custom TypeInfo", function()
			local expect: any = expect
			-- // This TypeInfo will never return a valid field.
			local typeInfo = TypeInfo.new(testSchema, function()
				return nil
			end)

			local doc = parse([[
				query {
					catOrDog {
						... on Cat {
							furColor
						}
						... on Dog {
							isHouseTrained
						}
					}
				}
			]])

			local errors = validate(testSchema, doc, nil, typeInfo)
			local errorMessages = Array.map(errors, function(err)
				return err.message
			end)

			expect(errorMessages).toEqual({
				'Cannot query field "catOrDog" on type "QueryRoot". Did you mean "catOrDog"?',
				'Cannot query field "furColor" on type "Cat". Did you mean "furColor"?',
				'Cannot query field "isHouseTrained" on type "Dog". Did you mean "isHouseTrained"?',
			})
		end)

		itSKIP("validates using a custom rule", function()
			local expect: any = expect
			local schema = buildSchema([[
				directive @custom(arg: String) on FIELD

				type Query {
					foo: String
				}
			]])
			local doc = parse([[
      query {
        name @custom
      }
			]])

			local function customRule(context)
				return {
					Directive = function(node)
						local directiveDef = context:getDirective()
						local error_ = GraphQLError.new(
							"Reporting directive: " .. tostring(directiveDef),
							node
						)
						context:reportError(error_)
					end,
				}
			end

			local errors = validate(schema, doc, {customRule})
			expect(errors).toEqual({
				{
					message = "Reporting directive: @custom",
					locations = {{ line = 3, column = 14 }},
				},
			})
		end)
	end)

	describe("Validate: Limit maximum number of validation errors", function()
		local query = [[
			{
				firstUnknownField
				secondUnknownField
				thirdUnknownField
			}
		]]
		local doc = parse(query, {noLocation = true})

		local function validateDocument(options)
			return validate(testSchema, doc, nil, nil, options)
		end

		local function invalidFieldError(fieldName: string)
			return {
				message = ('Cannot query field "%s" on type "QueryRoot".'):format(fieldName),
				locations = {}
			}
		end

		itSKIP("when maxError is equal number of errors", function()
			local expect: any = expect
			local errors = validateDocument({maxErrors = 3})
			expect(errors).toEqual({
				invalidFieldError("firstUnknownField"),
				invalidFieldError("secondUnknownField"),
				invalidFieldError("thirdUnknownField"),
			})
		end)

		itSKIP("when maxErrors is less than number of errors", function()
			local expect: any = expect
			local errors = validateDocument({maxErrors = 2})
			expect(errors).toEqual({
				invalidFieldError("firstUnknownField"),
				invalidFieldError("secondUnknownField"),
				{
					message = "Too many validation errors, error limit reached. Validation aborted.",
				},
			})
		end)

		itSKIP("passthrough exceptions from rules", function()
			local function customRule()
				return {
					Field = function()
						error(Error.new("Error from custom rule!"))
					end,
				}
			end
			local ok, errorResult = pcall(function()
				return validate(testSchema, doc, {customRule}, nil, {maxErrors = 1})
			end)
			expect(ok).to.equal(false)
			expect(errorResult.message).to.equal("Error from custom rule!")
		end)
	end)
end
