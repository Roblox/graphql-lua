-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/type/directives.js

local Workspace = script.Parent.Parent
local Packages = Workspace.Parent.Packages
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local objectEntries = require(script.Parent.Parent.polyfills.objectEntries).objectEntries
local inspect = require(script.Parent.Parent.jsutils.inspect).inspect
local toObjMap = require(script.Parent.Parent.jsutils.toObjMap).toObjMap
local devAssert = require(script.Parent.Parent.jsutils.devAssert).devAssert
local instanceOf = require(script.Parent.Parent.jsutils.instanceOf)
local isObjectLike = require(script.Parent.Parent.jsutils.isObjectLike).isObjectLike
local DirectiveLocation = require(script.Parent.Parent.language.directiveLocation).DirectiveLocation
local scalars = require(script.Parent.scalars)
local GraphQLString = scalars.GraphQLString
local GraphQLBoolean = scalars.GraphQLBoolean
local definition = require(script.Parent.definition)
local argsToArgsConfig = definition.argsToArgsConfig
local GraphQLNonNull = definition.GraphQLNonNull

local GraphQLDirective

--[[**
 * Test if the given value is a GraphQL directive.
 *]]
function isDirective(directive)
	return instanceOf(directive, GraphQLDirective)
end

function assertDirective(directive)
	if not isDirective(directive) then
		error(Error.new(("Expected %s to be a GraphQL directive."):format(inspect(directive))))
	end

	return directive
end

GraphQLDirective = {}
GraphQLDirective.__index = GraphQLDirective

--[[**
 * Directives are used by the GraphQL runtime as a way of modifying execution
 * behavior. Type system creators will usually not create these directly.
 */]]
function GraphQLDirective.new(config)
	local self = {}

	self.name = config.name
	self.description = config.description
	self.locations = config.locations
	self.isRepeatable = (function()
		local _ref = config.isRepeatable

		if _ref == nil then
			_ref = false
		end

		return _ref
	end)()
	self.extensions = config.extensions and toObjMap(config.extensions)
	self.astNode = config.astNode

	devAssert(config.name, "Directive must be named.")
	devAssert(
		Array.isArray(config.locations),
		("@%s locations must be an Array."):format(config.name)
	)

	local args = (function()
		local _ref = config.args

		if _ref == nil then
			_ref = {}
		end

		return _ref
	end)()

	-- ROBLOX deviation: empty table doesn't necessarily mean an array
	devAssert(
		isObjectLike(args) and not (Array.isArray(args) and next(args) ~= nil),
		("@%s args must be an object with argument names as keys."):format(config.name)
	)

	self.args = Array.map(objectEntries(args), function(entries)
		local argName, argConfig = entries[1], entries[2]

		return {
			name = argName,
			description = argConfig.description,
			type = argConfig.type,
			defaultValue = argConfig.defaultValue,
			deprecationReason = argConfig.deprecationReason,
			extensions = argConfig.extensions and toObjMap(argConfig.extensions),
			astNode = argConfig.astNode,
		}
	end)

	return setmetatable(self, GraphQLDirective)
end

function GraphQLDirective:toConfig()
	return {
		name = self.name,
		description = self.description,
		locations = self.locations,
		args = argsToArgsConfig(self.args),
		isRepeatable = self.isRepeatable,
		extensions = self.extensions,
		astNode = self.astNode,
	}
end

function GraphQLDirective.__tostring(self)
	return self:toString()
end

function GraphQLDirective:toString()
	return "@" .. self.name
end
function GraphQLDirective:toJSON()
	return self:toString()
end

--[[**
 * Used to conditionally include fields or fragments.
 *]]
local GraphQLIncludeDirective = GraphQLDirective.new({
	name = "include",
	description = "Directs the executor to include this field or fragment only when the `if` argument is true.",
	locations = {
		DirectiveLocation.FIELD,
		DirectiveLocation.FRAGMENT_SPREAD,
		DirectiveLocation.INLINE_FRAGMENT,
	},
	args = {
		["if"] = {
			type = GraphQLNonNull.new(GraphQLBoolean),
			description = "Included when true.",
		},
	},
})

--[[**
 * Used to conditionally skip (exclude) fields or fragments.
 *]]
local GraphQLSkipDirective = GraphQLDirective.new({
	name = "skip",
	description = "Directs the executor to skip this field or fragment when the `if` argument is true.",
	locations = {
		DirectiveLocation.FIELD,
		DirectiveLocation.FRAGMENT_SPREAD,
		DirectiveLocation.INLINE_FRAGMENT,
	},
	args = {
		["if"] = {
			type = GraphQLNonNull.new(GraphQLBoolean),
			description = "Skipped when true.",
		},
	},
})

--[[**
 * Constant string used for default reason for a deprecation.
 *]]
local DEFAULT_DEPRECATION_REASON = "No longer supported"

--[[**
 * Used to declare element of a GraphQL schema as deprecated.
 *]]
local GraphQLDeprecatedDirective = GraphQLDirective.new({
	name = "deprecated",
	description = "Marks an element of a GraphQL schema as no longer supported.",
	locations = {
		DirectiveLocation.FIELD_DEFINITION,
		DirectiveLocation.ARGUMENT_DEFINITION,
		DirectiveLocation.INPUT_FIELD_DEFINITION,
		DirectiveLocation.ENUM_VALUE,
	},
	args = {
		reason = {
			type = GraphQLString,
			description = "Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted using the Markdown syntax, as specified by [CommonMark](https://commonmark.org/).",
			defaultValue = DEFAULT_DEPRECATION_REASON,
		},
	},
})

--[[**
 * Used to provide a URL for specifying the behaviour of custom scalar definitions.
 *]]
local GraphQLSpecifiedByDirective = GraphQLDirective.new({
	name = "specifiedBy",
	description = "Exposes a URL that specifies the behaviour of this scalar.",
	locations = {
		DirectiveLocation.SCALAR,
	},
	args = {
		url = {
			type = GraphQLNonNull.new(GraphQLString),
			description = "The URL that specifies the behaviour of this scalar.",
		},
	},
})

--[[**
 * The full list of specified directives.
 *]]
local specifiedDirectives = Object.freeze({
	GraphQLIncludeDirective,
	GraphQLSkipDirective,
	GraphQLDeprecatedDirective,
	GraphQLSpecifiedByDirective,
})

local function isSpecifiedDirective(directive)
	return Array.some(specifiedDirectives, function(specifiedDirective)
		local name = specifiedDirective.name

		return name == directive.name
	end)
end

return {
	isDirective = isDirective,
	assertDirective = assertDirective,
	GraphQLDirective = GraphQLDirective,
	GraphQLIncludeDirective = GraphQLIncludeDirective,
	GraphQLSkipDirective = GraphQLSkipDirective,
	DEFAULT_DEPRECATION_REASON = DEFAULT_DEPRECATION_REASON,
	GraphQLDeprecatedDirective = GraphQLDeprecatedDirective,
	GraphQLSpecifiedByDirective = GraphQLSpecifiedByDirective,
	specifiedDirectives = specifiedDirectives,
	isSpecifiedDirective = isSpecifiedDirective,
}
