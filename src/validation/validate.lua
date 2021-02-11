-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/validation/validate.js

local validationWorkspace = script.Parent
local root = validationWorkspace.Parent
local devAssert = require(root.jsutils.devAssert).devAssert
local GraphQLError = require(root.error.GraphQLError).GraphQLError
local visitorExports = require(root.language.visitor)
local visit = visitorExports.visit
local visitInParallel = visitorExports.visitInParallel
-- local assertValidSchema = require(root.type.validate).assertValidSchema
local TypeInfoExports = require(root.utilities.TypeInfo)
local TypeInfo = TypeInfoExports.TypeInfo
local visitWithTypeInfo = TypeInfoExports.visitWithTypeInfo
local specifiedRulesImport = require(validationWorkspace.specifiedRules)
local specifiedRules = specifiedRulesImport.specifiedRules
local specifiedSDLRules = specifiedRulesImport.specifiedSDLRules
local ValidationContextExports = require(validationWorkspace.ValidationContext)
local SDLValidationContext = ValidationContextExports.SDLValidationContext
local ValidationContext = ValidationContextExports.ValidationContext
local Error = require(root.luaUtils.Error)
local PackagesWorkspace = root.Parent.Packages
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local Array = LuauPolyfill.Array

local exports = {}

-- /**
--  * Implements the "Validation" section of the spec.
--  *
--  * Validation runs synchronously, returning an array of encountered errors, or
--  * an empty array if no errors were encountered and the document is valid.
--  *
--  * A list of specific validation rules may be provided. If not provided, the
--  * default list of rules defined by the GraphQL specification will be used.
--  *
--  * Each validation rules is a function which returns a visitor
--  * (see the language/visitor API). Visitor methods are expected to return
--  * GraphQLErrors, or Arrays of GraphQLErrors when invalid.
--  *
--  * Optionally a custom TypeInfo instance may be provided. If not provided, one
--  * will be created from the provided schema.
--  */
exports.validate = function(
	schema,
	documentAST,
	rules,
	typeInfo,
	options
)
	if rules == nil then
		rules = specifiedRules
	end
	if typeInfo == nil then
		typeInfo = TypeInfo.new(schema)
	end
	if options == nil then
		options = {maxErrors = nil}
	end

	devAssert(documentAST, "Must provide document.")
	-- // If the schema used for validation is invalid, throw an error.
	-- ROBLOX FIXME: skip assertValidSchema until type/validate.js is converted
	-- assertValidSchema(schema)

	local abortObj = {}
	local errors = {}
	local context = ValidationContext.new(
		schema,
		documentAST,
		typeInfo,
		function(error_)
			if options.maxErrors ~= nil and #errors >= options.maxErrors then
				table.insert(
					errors,
					GraphQLError.new("Too many validation errors, error limit reached. Validation aborted.")
				)
				error(abortObj)
			end

			table.insert(errors, error_)
		end
	)

	-- // This uses a specialized visitor which runs multiple visitors in parallel,
	-- // while maintaining the visitor skip and break API.
	local visitor = visitInParallel(
		Array.map(rules, function(rule)
			return rule(context)
		end)
	)

	-- // Visit the whole document with each instance of all provided rules.
	local ok, result = pcall(function()
		visit(documentAST, visitWithTypeInfo(typeInfo, visitor))
	end)
	-- ROBLOX catch
	if not ok then
		if result ~= abortObj then
			error(result)
		end
	end
	return errors
end

-- /**
--  * @internal
--  */
exports.validateSDL = function(
	documentAST,
	schemaToExtend,
	rules
)
	if rules == nil then
		rules = specifiedSDLRules
	end
	local errors = {}
	local context = SDLValidationContext.new(
		documentAST,
		schemaToExtend,
		function(error_)
			table.insert(errors, error_)
		end
	)
	local visitors = Array.map(rules, function(rule)
		return rule(context)
	end)
	visit(documentAST, visitInParallel(visitors))
	return errors
end

-- /**
--  * Utility function which asserts a SDL document is valid by throwing an error
--  * if it is invalid.
--  *
--  * @internal
--  */
exports.assertValidSDL = function(documentAST)
	local errors = exports.validateSDL(documentAST)
	if #errors ~= 0 then
		error(Error.new(
			table.concat(
				Array.map(errors, function(error_)
					return error_.message
				end),
				'\n\n'
			)
		))
	end
end

-- /**
--  * Utility function which asserts a SDL document is valid by throwing an error
--  * if it is invalid.
--  *
--  * @internal
--  */
exports.assertValidSDLExtension = function(
	documentAST,
	schema
)
	local errors = exports.validateSDL(documentAST, schema)
	if #errors ~= 0 then
		error(Error.new(
			table.concat(
				Array.map(errors, function(error_)
					return error_.message
				end),
				'\n\n'
			)
		))
	end
end

return exports
