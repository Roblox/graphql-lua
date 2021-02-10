-- ROBLOX upstream: https://github.com/graphql/graphql-js/blob/aa650618426a301e3f0f61ead3adcd755055a627/src/utilities/buildASTSchema.js
local Array = require(script.Parent.Parent.Parent.Packages.LuauPolyfill).Array
local devAssertModule = require(script.Parent.Parent.jsutils.devAssert)
local devAssert = devAssertModule.devAssert
local kinds = require(script.Parent.Parent.language.kinds)
local Kind = kinds.Kind
local parser = require(script.Parent.Parent.language.parser)
local parse = parser.parse
-- local validate = require(script.Parent.Parent.validation.validate)
-- local assertValidSDL = validate.assertValidSDL
local schema = require(script.Parent.Parent.type.schema)
local GraphQLSchema = schema.GraphQLSchema
local directivesModule = require(script.Parent.Parent.type.directives)
local specifiedDirectives = directivesModule.specifiedDirectives
local extendSchema = require(script.Parent.extendSchema)
local extendSchemaImpl = extendSchema.extendSchemaImpl

local buildASTSchema = function(documentAST, options)
	devAssert(
		documentAST ~= nil and documentAST.kind == Kind.DOCUMENT,
		"Must provide valid Document AST."
	)

	-- if  options ~= nil and not (options.assumeValid or options.assumeValidSDL) then
	--     -- ROBLOX FIXME: introduce this when validation directory is merged
	-- 	-- assertValidSDL(documentAST)
	-- end

	local emptySchemaConfig = {
		description = nil,
		types = {},
		directives = {},
		extensions = nil,
		extensionASTNodes = {},
		assumeValid = false,
	}
	local config = extendSchemaImpl(emptySchemaConfig, documentAST, options)

	if config.astNode == nil then
		for _, type_ in ipairs(config.types) do
			if type_.name == "Query" then
				config.query = type_
			elseif type_.name == "Mutation" then
				config.mutation = type_
			elseif type_.name == "Subscription" then
				config.subscription = type_
			end
		end
	end

	local directives = config.directives

	for _, stdDirective in ipairs(specifiedDirectives) do
		if Array.every(directives, function(directive)
			return directive.name ~= stdDirective.name
		end) then
			table.insert(directives, stdDirective)
		end
	end

	return GraphQLSchema.new(config)
end

local function buildSchema(source, options)
	local document = parse(source, {
		noLocation = (function()
			if options ~= nil then
				return options.noLocation
			end
			return options
		end)(),
		experimentalFragmentVariables = (function()
			if options ~= nil then
				return options.experimentalFragmentVariables
			end
			return options
		end)(),
	})

	return buildASTSchema(document, {
		assumeValidSDL = (function()
			if options ~= nil then
				return options.assumeValidSDL
			end
			return options
		end)(),
		assumeValid = (function()
			if options ~= nil then
				return options.assumeValid
			end
			return options
		end)(),
	})
end

return {
	buildASTSchema = buildASTSchema,
	buildSchema = buildSchema,
}