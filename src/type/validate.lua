-- ROBLOX upstream:
-- ROBLOX deviation: selene suppression
--# selene: allow(if_same_then_else)

type Array<T> = { [number]: T }
type Set<T> = { [T]: boolean }
local srcWorkspace = script.Parent.Parent
local root = srcWorkspace.Parent
local LuauPolyfill = require(root.Packages.LuauPolyfill)
local Array = require(srcWorkspace.luaUtils.Array)
local Error = LuauPolyfill.Error
local Boolean = LuauPolyfill.Boolean

local objectValues = require(script.Parent.Parent.polyfills.objectValues).objectValues
local inspect = require(script.Parent.Parent.jsutils.inspect).inspect
local GraphQLErrorModule = require(script.Parent.Parent.error.GraphQLError)
local GraphQLError = GraphQLErrorModule.GraphQLError
type GraphQLError = GraphQLErrorModule.GraphQLError
local locatedError = require(script.Parent.Parent.error).locatedError

local astModule = require(srcWorkspace.language.ast)
type ASTNode = astModule.ASTNode
type NamedTypeNode = astModule.NamedTypeNode
type DirectiveNode = astModule.DirectiveNode
type OperationTypeNode = astModule.OperationTypeNode

local isValidNameError = require(srcWorkspace.utilities.assertValidName).isValidNameError
local typeComparators = require(script.Parent.Parent.utilities.typeComparators)
local isEqualType = typeComparators.isEqualType
local isTypeSubTypeOf = typeComparators.isTypeSubTypeOf
local schemaModule = require(script.Parent.schema)
local assertSchema = schemaModule.assertSchema

type GraphQLSchema = schemaModule.GraphQLSchema
local definition = require(script.Parent.definition)
-- type GraphQLObjectType = definition.GraphQLObjectType
-- type GraphQLInterfaceType = definition.GraphQLInterfaceType
-- type GraphQLUnionType = definition.GraphQLUnionType
-- type GraphQLEnumType = definition.GraphQLEnumType
-- type GraphQLInputObjectType = definition.GraphQLInputObjectType

local isIntrospectionType = require(script.Parent.introspection).isIntrospectionType
local directives = require(script.Parent.directives)
local isDirective = directives.isDirective
local GraphQLDeprecatedDirective = directives.GraphQLDeprecatedDirective
local isObjectType = definition.isObjectType
local isInterfaceType = definition.isInterfaceType
local isUnionType = definition.isUnionType
local isEnumType = definition.isEnumType
local isInputObjectType = definition.isInputObjectType
local isNamedType = definition.isNamedType
local isNonNullType = definition.isNonNullType
local isInputType = definition.isInputType
local isOutputType = definition.isOutputType
local isRequiredArgument = definition.isRequiredArgument
local isRequiredInputField = definition.isRequiredInputField

local SchemaValidationContext, validateRootTypes, validateDirectives, getOperationTypeNode, getAllSubNodes, getAllNodes, getAllImplementsInterfaceNodes, getDeprecatedDirectiveNode, getUnionMemberTypeNodes, validateEnumValues, validateName, validateFields, validateTypeImplementsAncestors, validateTypes, validateTypeImplementsInterface, validateInterfaces
--[[*
 * Implements the "Type Validation" sub-sections of the specification's
 * "Type System" section.
 *
 * Validation runs synchronously, returning an array of encountered errors, or
 * an empty array if no errors were encountered and the Schema is valid.
 ]]
local validateSchema = function(
	schema: GraphQLSchema
): Array<GraphQLError>?
	-- First check to ensure the provided value is in fact a GraphQLSchema.
	assertSchema(schema)

	-- If this Schema has already been validated, return the previous results.
	if schema.__validationErrors ~= nil then
		return schema.__validationErrors
	end

	--  Validate the schema, producing a list of errors.
	local context = SchemaValidationContext.new(schema)
	validateRootTypes(context)
	validateDirectives(context)
	validateTypes(context)

	-- Persist the results of validation before returning to ensure validation
	-- does not run multiple times for this schema.
	local errors = context:getErrors()

	schema.__validationErrors = errors

	return errors
end

--[[*
 * Utility function which asserts a schema is valid by throwing an error if
 * it is invalid.
 ]]
local assertValidSchema = function(schema: GraphQLSchema): ()
	local errors = validateSchema(schema)

	if #errors ~= 0 then
		error(Error.new(Array.join(
			Array.map(errors, function(error_)
				return error_.message
			end),
			"\n\n"
		)))
	end
end

type SchemaValidationContext = {
	_errors: Array<GraphQLError>,
	schema: GraphQLSchema,
}
SchemaValidationContext = {}
SchemaValidationContext.__index = SchemaValidationContext

function SchemaValidationContext.new(schema: GraphQLSchema): SchemaValidationContext
	local self = {}

	self._errors = {}
	self.schema = schema

	return setmetatable(self, SchemaValidationContext)
end

function SchemaValidationContext:reportError(
	message: string,
	nodes: Array<ASTNode?> | ASTNode?
): ()
	local _nodes
	if Array.isArray(nodes) then
		_nodes = Array.filter(nodes, Boolean.toJSBoolean)
	else
		_nodes = nodes
	end

	self:addError(GraphQLError.new(message, _nodes))
end

function SchemaValidationContext:addError(error_: GraphQLError): ()
	table.insert(self._errors, error_)
end

function SchemaValidationContext:getErrors(): Array<GraphQLError>
	return self._errors
end

-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/type/validate.js
function validateRootTypes(context: SchemaValidationContext): ()
	local schema = context.schema
	local queryType = schema:getQueryType()

	if not queryType then
		context:reportError("Query root type must be provided.", schema.astNode)
	elseif not isObjectType(queryType) then
		context:reportError(
			("Query root type must be Object type, it cannot be %s."):format(inspect(queryType)),
			(function()
				local _ref = getOperationTypeNode(schema, "query")

				if _ref == nil then
					_ref = queryType.astNode
				end

				return _ref
			end)()
		)
	end

	local mutationType = schema:getMutationType()

	if mutationType and not isObjectType(mutationType) then
		context:reportError(
			"Mutation root type must be Object type if provided, it cannot be " .. ("%s."):format(inspect(mutationType)),
			(function()
				local _ref = getOperationTypeNode(schema, "mutation")

				if _ref == nil then
					_ref = mutationType.astNode
				end

				return _ref
			end)()
		)
	end

	local subscriptionType = schema:getSubscriptionType()

	if subscriptionType and not isObjectType(subscriptionType) then
		context:reportError(
			"Subscription root type must be Object type if provided, it cannot be " .. ("%s."):format(inspect(subscriptionType)),
			(function()
				local _ref = getOperationTypeNode(schema, "subscription")

				if _ref == nil then
					_ref = subscriptionType.astNode
				end

				return _ref
			end)()
		)
	end
end
function getOperationTypeNode(
	schema: SchemaValidationContext,
	operation: OperationTypeNode
):ASTNode?
	local operationNodes = getAllSubNodes(schema, function(node)
		return node.operationTypes
	end)

	for _, node in ipairs(operationNodes) do
		if node.operation == operation then
			return node.type
		end
	end

	return nil
end

function validateDirectives(context: SchemaValidationContext): ()
	for _, directive in ipairs(context.schema:getDirectives()) do
		-- Ensure all directives are in fact GraphQL directives.
		if not isDirective(directive) then
			context:reportError(
				("Expected directive but got: %s."):format(inspect(directive)),
				(function()
					if directive ~= nil then
						return directive.astNode
					end
					return
				end)()
			)
			continue
		end

		-- Ensure they are named correctly.
		validateName(context, directive)

		-- TODO: Ensure proper locations.

		-- Ensure the arguments are valid.
		for _, arg in ipairs(directive.args) do
			validateName(context, arg)

			-- Ensure the type is an input type.
			if not isInputType(arg.type) then
				context:reportError(
					("The type of @%s(%s:) must be Input Type "):format(directive.name, arg.name) .. ("but got: %s."):format(inspect(arg.type)),
					arg.astNode
				)
			end

			if isRequiredArgument(arg) and arg.deprecationReason ~= nil then

				context:reportError(
					("Required argument @%s(%s:) cannot be deprecated."):format(directive.name, arg.name),
					{
						getDeprecatedDirectiveNode(arg.astNode),
						(function()
							-- istanbul ignore next (TODO need to write coverage tests)
							if arg.astNode ~= nil then
								return arg.astNode.type
							end
							return
						end)(),
					}
				)
			end
		end
	end
end
function validateName(
	context: SchemaValidationContext,
	node
): ()
	-- Ensure names are valid, however introspection types opt out.
	-- ROBLOX deviation: Lua doesn't allow indexing (name) into a function
	local nodeName
	local nodeAstNode
	if typeof(node) == "table" then
		nodeName = node.name
		nodeAstNode = node.astNode
	else
		nodeName = tostring(node)
	end
	local error_ = isValidNameError(nodeName)

	if error_ then
		context:addError(locatedError(error_, nodeAstNode))
	end
end

function validateTypes(context: SchemaValidationContext): ()
	local validateInputObjectCircularRefs = createInputObjectCircularRefsValidator(context)
	local typeMap = context.schema:getTypeMap()

	-- ROBLOX deviation: use Map type
	for _, type_ in ipairs(typeMap:values()) do
		-- Ensure all provided types are in fact GraphQL type.
		-- ROBLOX deviation: Lua doesn't allow indexing into a function
		local typeAstNode
		if typeof(type_) == "table" then
			typeAstNode = type_.astNode
		end
		if not isNamedType(type_) then
			context:reportError(("Expected GraphQL named type but got: %s."):format(inspect(type_)), typeAstNode)
			continue
		end

		-- Ensure it is named correctly (excluding introspection types).
		if not isIntrospectionType(type_) then
			validateName(context, type_)
		end

		if isObjectType(type_) then
			-- Ensure fields are valid
			validateFields(context, type_)
			-- Ensure objects implement the interfaces they claim to.
			validateInterfaces(context, type_)
		elseif isInterfaceType(type_) then
			-- Ensure fields are valid.
			validateFields(context, type_)
			-- Ensure interfaces implement the interfaces they claim to.
			validateInterfaces(context, type_)
		elseif isUnionType(type_) then
			-- Ensure Unions include valid member types.
			validateUnionMembers(context, type_)
		elseif isEnumType(type_) then
			-- Ensure Enums have valid values.
			validateEnumValues(context, type_)
		elseif isInputObjectType(type_) then
			-- Ensure Input Object fields are valid.
			validateInputFields(context, type_)

			-- Ensure Input Objects do not contain non-nullable circular references
			validateInputObjectCircularRefs(type_)
		end
	end
end

function validateFields(
	context: SchemaValidationContext,
	type_ --: GraphQLObjectType | GraphQLInterfaceType
): ()
	local fields = objectValues(type_:getFields())

	-- Objects and Interfaces both must define one or more fields.
	if #fields == 0 then
		context:reportError(
			("Type %s must define one or more fields."):format(type_.name),
			getAllNodes(type_)
		)
	end

	for _, field in ipairs(fields) do
		-- Ensure they are named correctly.
		validateName(context, field)

		-- Ensure the type is an output type
		if not isOutputType(field.type) then
			context:reportError(
				("The type of %s.%s must be Output Type "):format(type_.name, field.name) .. ("but got: %s."):format(inspect(field.type)),
				(function()
					if field.astNode ~= nil then
						-- istanbul ignore next (TODO need to write coverage tests)
						return field.astNode.type
					end
					return
				end)()
			)
		end

		-- Ensure the arguments are valid
		for _, arg in ipairs(field.args) do
			local argName = arg.name

			-- Ensure they are named correctly.
			validateName(context, arg)

			-- Ensure the type is an input type
			if not isInputType(arg.type) then
				context:reportError(
					("The type of %s.%s(%s:) must be Input "):format(type_.name, field.name, argName) .. ("Type but got: %s."):format(inspect(arg.type)),
					(function()
						if field.astNode ~= nil then
							-- istanbul ignore next (TODO need to write coverage tests)
							return field.astNode.type
						end
						return
					end)()
				)
			end
			if isRequiredArgument(arg) and arg.deprecationReason ~= nil then
				context:reportError(
					("Required argument %s.%s(%s:) cannot be deprecated."):format(type_.name, field.name, argName),
					{
						getDeprecatedDirectiveNode(arg.astNode),
						(function()
							if field.astNode ~= nil then
								-- istanbul ignore next (TODO need to write coverage tests)
								return field.astNode.type
							end
							return
						end)(),
					}
				)
			end
		end
	end
end
function validateInterfaces(
	context: SchemaValidationContext,
	type_ --: GraphQLObjectType | GraphQLInterfaceType
): ()
	local ifaceTypeNames = {}

	for _, iface in ipairs(type_:getInterfaces()) do
		if not isInterfaceType(iface) then
			context:reportError(
				("Type %s must only implement Interface types, "):format(inspect(type_)) .. ("it cannot implement %s."):format(inspect(iface)),
				getAllImplementsInterfaceNodes(type_, iface)
			)
			continue
		end
		if type_ == iface then
			context:reportError(
				("Type %s cannot implement itself because it would create a circular reference."):format(type_.name),
				getAllImplementsInterfaceNodes(type_, iface)
			)
			continue
		end

		-- ROBLOX deviation: Lua can't deref fields on functions/primitives
		local ifaceName
		if typeof(ifaceName) == "table" then
			ifaceName = tostring(iface.name)
		else
			ifaceName = tostring(iface)
		end

		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		if ifaceTypeNames[ifaceName] then
			context:reportError(
				("Type %s can only implement %s once."):format(type_.name, iface.name),
				getAllImplementsInterfaceNodes(type_, iface)
			)
			continue
		end

		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		ifaceTypeNames[ifaceName] = true

		validateTypeImplementsAncestors(context, type_, iface)
		validateTypeImplementsInterface(context, type_, iface)
	end
end
function validateTypeImplementsInterface(
	context: SchemaValidationContext,
	type_, --: GraphQLObjectType | GraphQLInterfaceType,
	iface --: GraphQLInterfaceType
)
	local typeFieldMap = type_:getFields()

	-- Assert each interface field is implemented.
	for _, ifaceField in ipairs(objectValues(iface:getFields())) do
		local fieldName = ifaceField.name
		local typeField = typeFieldMap[fieldName]

		-- Assert interface field exists on type.
		if not typeField then
			context:reportError(
				("Interface field %s.%s expected but %s does not provide it."):format(iface.name, fieldName, type_.name),
				Array.concat({
					ifaceField.astNode,
				}, getAllNodes(type_))
			)
			continue
		end

		-- Assert interface field type is satisfied by type field type, by being
		-- a valid subtype. (covariant)
		if not isTypeSubTypeOf(context.schema, typeField.type, ifaceField.type) then

			context:reportError(
				("Interface field %s.%s expects type "):format(iface.name, fieldName) .. ("%s but %s.%s "):format(inspect(ifaceField.type), type_.name, fieldName) .. ("is type %s."):format(inspect(typeField.type)),
				{
					(function()
						if ifaceField.astNode ~= nil then
							-- istanbul ignore next (TODO need to write coverage tests)
							return ifaceField.astNode.type
						end
						return
					end)(),
					(function()
						if typeField.astNode ~= nil then
							-- istanbul ignore next (TODO need to write coverage tests)
							return typeField.astNode.type
						end
						return
					end)(),
				}
			)
		end

		-- Assert each interface field arg is implemented.
		for _, ifaceArg in ipairs(ifaceField.args) do
			local argName = ifaceArg.name
			local typeArg = Array.find(typeField.args, function(arg)
				return arg.name == argName
			end)

			-- Assert interface field arg exists on object field.
			if not typeArg then
				context:reportError(
					("Interface field argument %s.%s(%s:) expected but %s.%s does not provide it."):format(iface.name, fieldName, argName, type_.name, fieldName),
					{
						ifaceArg.astNode,
						typeField.astNode,
					}
				)
				continue
			end

			-- Assert interface field arg type matches object field arg type.
			-- (invariant)
			-- TODO: change to contravariant?
			if not isEqualType(ifaceArg.type, typeArg.type) then

				context:reportError(
					("Interface field argument %s.%s(%s:) "):format(iface.name, fieldName, argName) .. ("expects type %s but "):format(inspect(ifaceArg.type)) .. ("%s.%s(%s:) is type "):format(type_.name, fieldName, argName) .. ("%s."):format(inspect(typeArg.type)),
					{
						(function()
							if ifaceArg.astNode ~= nil then
								-- istanbul ignore next (TODO need to write coverage tests)
								return ifaceArg.astNode.type
							end
							return
						end)(),
						(function()
							if typeArg.astNode ~= nil then
								-- istanbul ignore next (TODO need to write coverage tests)
								return typeArg.astNode.type
							end
							return
						end)(),
					}
				)
			end
			-- TODO: validate default values?
		end

		-- Assert additional arguments must not be required.
		for _, typeArg in ipairs(typeField.args) do
			local argName = typeArg.name
			local ifaceArg = Array.find(ifaceField.args, function(arg)
				return arg.name == argName
			end)

			if not ifaceArg and isRequiredArgument(typeArg) then
				context:reportError(
					("Object field %s.%s includes required argument %s that is missing from the Interface field %s.%s."):format(type_.name, fieldName, argName, iface.name, fieldName),
					{
						typeArg.astNode,
						ifaceField.astNode,
					}
				)
			end
		end
	end
end

function validateTypeImplementsAncestors(
	context: SchemaValidationContext,
	type_, --: GraphQLObjectType | GraphQLInterfaceType,
	iface --: GraphQLInterfaceType
): ()
	local ifaceInterfaces = type_:getInterfaces()

	for _, transitive in ipairs(iface:getInterfaces()) do
		if Array.indexOf(ifaceInterfaces, transitive) == -1 then
			context:reportError(
				(function()
					if transitive == type_ then
						return ("Type %s cannot implement %s because it would create a circular reference."):format(type_.name, iface.name)
					end

					return ("Type %s must implement %s because it is implemented by %s."):format(type_.name, transitive.name, iface.name)
				end)(),
				{
					Array.concat(
						getAllImplementsInterfaceNodes(iface, transitive),
						getAllImplementsInterfaceNodes(type_, iface)
					),
				}
			)
		end
	end
end

function validateUnionMembers(
	context: SchemaValidationContext,
	union -- : GraphQLUnionType
): ()
	local memberTypes = union:getTypes()

	if #memberTypes == 0 then
		context:reportError(
			("Union type %s must define one or more member types."):format(union.name),
			getAllNodes(union)
		)
	end

	local includedTypeNames = {}

	for _, memberType in ipairs(memberTypes) do
		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		if includedTypeNames[tostring(memberType.name)] then
			context:reportError(
				("Union type %s can only include type %s once."):format(union.name, memberType.name),
				getUnionMemberTypeNodes(union, memberType.name)
			)
			continue
		end

		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		includedTypeNames[tostring(memberType.name)] = true

		if not isObjectType(memberType) then
			context:reportError(
				("Union type %s can only include Object types, "):format(union.name) .. ("it cannot include %s."):format(inspect(memberType)),
				getUnionMemberTypeNodes(union, tostring(memberType))
			)
		end
	end
end
function validateEnumValues(
	context: SchemaValidationContext,
	enumType --: GraphQLEnumType
): ()
	local enumValues = enumType:getValues()

	if #enumValues == 0 then
		context:reportError(
			("Enum type %s must define one or more values."):format(enumType.name),
			getAllNodes(enumType)
		)
	end

	for _, enumValue in ipairs(enumValues) do
		local valueName = enumValue.name

		-- Ensure valid name.
		validateName(context, enumValue)

		if valueName == "true" or valueName == "false" or valueName == "null" then
			context:reportError(
				("Enum type %s cannot include value: %s."):format(enumType.name, valueName),
				enumValue.astNode
			)
		end
	end
end

function validateInputFields(
	context: SchemaValidationContext,
	inputObj --: GraphQLInputObjectType
): ()
	local fields = objectValues(inputObj:getFields())

	if #fields == 0 then
		context:reportError(
			("Input Object type %s must define one or more fields."):format(inputObj.name),
			getAllNodes(inputObj)
		)
	end

	-- Ensure the arguments are valid
	for _, field in ipairs(fields) do
		validateName(context, field)

		-- Ensure the type is an input type
		if not isInputType(field.type) then
			context:reportError(
				("The type of %s.%s must be Input Type "):format(inputObj.name, field.name) .. ("but got: %s."):format(inspect(field.type)),
				(function()
					if field.astNode ~= nil then
						-- istanbul ignore next (TODO need to write coverage tests)
						return field.astNode.type
					end
					return
				end)()
			)
		end
		if isRequiredInputField(field) and field.deprecationReason ~= nil then
			context:reportError(
				("Required input field %s.%s cannot be deprecated."):format(inputObj.name, field.name),
				{
					getDeprecatedDirectiveNode(field.astNode),
					(function()
						if field.astNode ~= nil then
							-- istanbul ignore next (TODO need to write coverage tests)
							return field.astNode.type
						end
						return
					end)(),
				}
			)
		end
	end
end

function createInputObjectCircularRefsValidator(
	context: SchemaValidationContext
): (any) -> ()
	-- Modified copy of algorithm from 'src/validation/rules/NoFragmentCycles.lua'.
	-- Tracks already visited types to maintain O(N) and to ensure that cycles
	-- are not redundantly reported.
	local visitedTypes = {}

	-- Array of types nodes used to produce meaningful errors
	local fieldPath = {}

	-- Position in the type path
	local fieldPathIndexByTypeName = {}

	-- This does a straight-forward DFS to find cycles.
	-- It does not terminate when a cycle was found but continues to explore
	-- the graph to find all possible cycles.
	local function detectCycleRecursive(inputObj): () --: GraphQLInputObjectType): ()
		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		if visitedTypes[tostring(inputObj.name)] then
			return
		end

		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		visitedTypes[tostring(inputObj.name)] = true
		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		fieldPathIndexByTypeName[tostring(inputObj.name)] = #fieldPath

		local fields = objectValues(inputObj:getFields())

		for _, field in ipairs(fields) do
			if isNonNullType(field.type) and isInputObjectType(field.type.ofType) then
				local fieldType = field.type.ofType
				-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
				local cycleIndex = fieldPathIndexByTypeName[tostring(fieldType.name)]

				table.insert(fieldPath, field)

				if cycleIndex == nil then
					detectCycleRecursive(fieldType)
				else
					-- ROBLOX FiXME? This is a gross workaround since our slice() polyfill doesn't return a shallow copy for a 0 index
					local cyclePath
					if cycleIndex == 0 then
						cyclePath = Array.slice(fieldPath, 1)
					else
						cyclePath = Array.slice(fieldPath, cycleIndex)
					end
					local pathStr = Array.join(
						Array.map(cyclePath, function(fieldObj)
							return fieldObj.name
						end),
						"."
					)

					context:reportError(
						("Cannot reference Input Object \"%s\" within itself through a series of non-null fields: \"%s\"."):format(fieldType.name, pathStr),
						Array.map(cyclePath, function(fieldObj)
							return fieldObj.astNode
						end)
					)
				end

				table.remove(fieldPath)
			end
		end

		-- ROBLOX deviation: upstream can receive a GraphQLList with no name member, but Lua can't store a nil key
		fieldPathIndexByTypeName[tostring(inputObj.name)] = nil
	end

	return detectCycleRecursive
end

-- ROBLOX TODO: revisit when Luau generic types are delivered
-- type SDLDefinedObject<T, K> = {
-- 	astNode: T?,
-- 	extensionASTNodes: Array<K>?,
-- }
type SDLDefinedObject = {
	astNode: any?,
	extensionASTNodes: Array<any>?,
}

-- ROBLOX TODO: revisit these types:
-- function getAllNodes<T: ASTNode, K: ASTNode>(
-- 	object: SDLDefinedObject<T, K>,
--   ): $ReadOnlyArray<T | K> {
function getAllNodes(object: SDLDefinedObject): Array<any>
	local astNode, extensionASTNodes = object.astNode, object.extensionASTNodes

	return (function()
		if astNode then
			return (function()
				if extensionASTNodes then
					return Array.concat({ astNode }, extensionASTNodes)
				end

				return { astNode }
			end)()
		end

		return (function()
			local _ref = extensionASTNodes

			if _ref == nil then
				_ref = {}
			end

			return _ref
		end)()
	end)()
end

-- ROBLOX TODO: revisit these generic function declarations
-- function getAllSubNodes<T: ASTNode, K: ASTNode, L: ASTNode>(
-- 	object: SDLDefinedObject<T, K>,
-- 	getter: (T | K) => ?(L | $ReadOnlyArray<L>),
--   ): $ReadOnlyArray<L> {
function getAllSubNodes(object, getter): Array<any>
	local subNodes = {}

	for _, node in ipairs(getAllNodes(object)) do
		-- istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
		subNodes = Array.concat(
			subNodes,
			(function()
				local _ref = getter(node)

				if _ref == nil then
					_ref = {}
				end

				return _ref
			end)()
		)
	end

	return subNodes
end

function getAllImplementsInterfaceNodes(
	type_, --: GraphQLObjectType | GraphQLInterfaceType,
	iface --: GraphQLInterfaceType
): Array<NamedTypeNode>
	return Array.filter(
		getAllSubNodes(type_, function(typeNode)
			return typeNode.interfaces
		end),
		function(ifaceNode)
			return ifaceNode.name.value == iface.name
		end
	)
end

function getUnionMemberTypeNodes(
	union, --: GraphQLUnionType,
	typeName --: string
): Array<NamedTypeNode>
	return Array.filter(
		getAllSubNodes(union, function(unionNode)
			return unionNode.types
		end),
		function(typeNode)
			return typeNode.name.value == typeName
	end)
end

function getDeprecatedDirectiveNode(definitionNode): DirectiveNode?
	if definitionNode ~= nil and definitionNode.directive ~= nil then
		-- istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
		return Array.find(definitionNode.directives, function(node)
			return node.name.value == GraphQLDeprecatedDirective.name
		end)
	end
	return
end

return {
	validateSchema = validateSchema,
	assertValidSchema = assertValidSchema,
}
