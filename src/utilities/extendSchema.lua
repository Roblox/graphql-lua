-- upstream: https://github.com/graphql/graphql-js/blob/4931f93f297511c6f8465d0c8104b20388a517e8/src/utilities/extendSchema.js

local srcWorkspace = script.Parent.Parent
local root = srcWorkspace.Parent

-- ROBLOX deviation: use Map type
local Map = require(srcWorkspace.luaUtils.Map).Map

local jsutils = srcWorkspace.jsutils
local keyMap = require(jsutils.keyMap).keyMap
local inspect = require(jsutils.inspect).inspect
local mapValue = require(jsutils.mapValue).mapValue
local invariant = require(jsutils.invariant).invariant
local devAssert = require(jsutils.devAssert).devAssert

local _astImport = require(srcWorkspace.language.ast)
type DocumentNode = _astImport.DocumentNode
type TypeNode = _astImport.TypeNode
type NamedTypeNode = _astImport.NamedTypeNode
type SchemaDefinitionNode = _astImport.SchemaDefinitionNode
type SchemaExtensionNode = _astImport.SchemaExtensionNode
type TypeDefinitionNode = _astImport.TypeDefinitionNode
type InterfaceTypeDefinitionNode = _astImport.InterfaceTypeDefinitionNode
type InterfaceTypeExtensionNode = _astImport.InterfaceTypeExtensionNode
type ObjectTypeDefinitionNode = _astImport.ObjectTypeDefinitionNode
type ObjectTypeExtensionNode = _astImport.ObjectTypeExtensionNode
type UnionTypeDefinitionNode = _astImport.UnionTypeDefinitionNode
type UnionTypeExtensionNode = _astImport.UnionTypeExtensionNode
type FieldDefinitionNode = _astImport.FieldDefinitionNode
type InputObjectTypeDefinitionNode = _astImport.InputObjectTypeDefinitionNode
type InputObjectTypeExtensionNode = _astImport.InputObjectTypeExtensionNode
type InputValueDefinitionNode = _astImport.InputValueDefinitionNode
type EnumTypeDefinitionNode = _astImport.EnumTypeDefinitionNode
type EnumTypeExtensionNode = _astImport.EnumTypeExtensionNode
type EnumValueDefinitionNode = _astImport.EnumValueDefinitionNode
type DirectiveDefinitionNode = _astImport.DirectiveDefinitionNode
type ScalarTypeDefinitionNode = _astImport.ScalarTypeDefinitionNode
type ScalarTypeExtensionNode = _astImport.ScalarTypeExtensionNode
local Kind = require(srcWorkspace.language.kinds).Kind

local predicates = require(srcWorkspace.language.predicates)
local isTypeDefinitionNode = predicates.isTypeDefinitionNode
local isTypeExtensionNode = predicates.isTypeExtensionNode

local assertValidSDLExtension = require(srcWorkspace.validation.validate).assertValidSDLExtension

local getDirectiveValues = require(srcWorkspace.execution.values).getDirectiveValues

local typeWorkspace = srcWorkspace.type
local schemaImport = require(typeWorkspace.schema)
type GraphQLSchemaValidationOptions = schemaImport.GraphQLSchemaValidationOptions
local assertSchema = schemaImport.assertSchema
local GraphQLSchema = schemaImport.GraphQLSchema
local scalarsImport = require(typeWorkspace.scalars)
local specifiedScalarTypes = scalarsImport.specifiedScalarTypes
local isSpecifiedScalarType = scalarsImport.isSpecifiedScalarType
local introspectionImport = require(typeWorkspace.introspection)
local introspectionTypes = introspectionImport.introspectionTypes
local isIntrospectionType = introspectionImport.isIntrospectionType
local directives = require(typeWorkspace.directives)
type GraphQLDirective = any -- directives.GraphQLDirective
local GraphQLDirective = directives.GraphQLDirective
local GraphQLDeprecatedDirective = directives.GraphQLDeprecatedDirective
local GraphQLSpecifiedByDirective = directives.GraphQLSpecifiedByDirective

local definitionImport = require(typeWorkspace.definition)
type GraphQLType = any -- definitionImport.GraphQLType
type GraphQLNamedType = any -- definitionImport.GraphQLNamedType
type GraphQLFieldConfig<T, U> = any -- definitionImport.GraphQLFieldConfig
type GraphQLFieldConfigMap<T, U> = any -- definitionImport.GraphQLFieldConfigMap
type GraphQLArgumentConfig = any -- definitionImport.GraphQLArgumentConfig
type GraphQLFieldConfigArgumentMap = any -- definitionImport.GraphQLFieldConfigArgumentMap
type GraphQLEnumValueConfigMap = any -- definitionImport.GraphQLEnumValueConfigMap
type GraphQLInputFieldConfigMap = any -- definitionImport.GraphQLInputFieldConfigMap
local isScalarType = definitionImport.isScalarType
local isObjectType = definitionImport.isObjectType
local isInterfaceType = definitionImport.isInterfaceType
local isUnionType = definitionImport.isUnionType
local isListType = definitionImport.isListType
local isNonNullType = definitionImport.isNonNullType
local isEnumType = definitionImport.isEnumType
local isInputObjectType = definitionImport.isInputObjectType
local GraphQLList = definitionImport.GraphQLList
local GraphQLNonNull = definitionImport.GraphQLNonNull
local GraphQLScalarType = definitionImport.GraphQLScalarType
type GraphQLScalarType = any -- definitionImport.GraphQLScalarType
local GraphQLObjectType = definitionImport.GraphQLObjectType
type GraphQLObjectType = any -- definitionImport.GraphQLObjectType
local GraphQLInterfaceType = definitionImport.GraphQLInterfaceType
type GraphQLInterfaceType = any -- definitionImport.GraphQLInterfaceType
local GraphQLUnionType = definitionImport.GraphQLUnionType
type GraphQLUnionType = any -- definitionImport.GraphQLUnionType
local GraphQLEnumType = definitionImport.GraphQLEnumType
type GraphQLEnumType = any -- definitionImport.GraphQLEnumType
local GraphQLInputObjectType = definitionImport.GraphQLInputObjectType
type GraphQLInputObjectType = any -- definitionImport.GraphQLInputObjectType

local valueFromAST = require(script.Parent.valueFromAST).valueFromAST

local LuauPolyfillImport = require(root.Packages.LuauPolyfill)
local Object = LuauPolyfillImport.Object
local Error = require(srcWorkspace.luaUtils.Error)
local Array = require(srcWorkspace.luaUtils.Array)

-- ROBLOX deviation: pre-declare variables
local stdTypeMap
local getDeprecationReason
local getSpecifiedByUrl

type Array<T> = { [number]: T }
type Options = GraphQLSchemaValidationOptions & {
	-- /**
	--  * Set to true to assume the SDL is valid.
	--  *
	--  * Default: false
	--  */
	assumeValidSDL: boolean?,
}

-- /**
--  * Produces a new schema given an existing schema and a document which may
--  * contain GraphQL type extensions and definitions. The original schema will
--  * remain unaltered.
--  *
--  * Because a schema represents a graph of references, a schema cannot be
--  * extended without effectively making an entire copy. We do not know until it's
--  * too late if subgraphs remain unchanged.
--  *
--  * This algorithm copies the provided schema, applying extensions while
--  * producing the copy. The original schema remains unaltered.
--  */
local function extendSchema(
	schema,
	documentAST,
	options: Options
)
	assertSchema(schema)

	devAssert(
		documentAST ~= nil and documentAST.kind == Kind.DOCUMENT,
		"Must provide valid Document AST."
	)

	if (options and options.assumeValid) ~= true and (options and options.assumeValidSDL) ~= true then
		assertValidSDLExtension(documentAST, schema)
	end

	local schemaConfig = schema:toConfig()
	local extendedConfig = extendSchemaImpl(schemaConfig, documentAST, options)
	return (function()
		if schemaConfig == extendedConfig then
			return schema
		else
			return GraphQLSchema.new(extendedConfig)
		end
	end)()
end

-- /**
--  * @internal
--  */
function extendSchemaImpl(
	schemaConfig,
	documentAST,
	options: Options
)
	-- // Collect the type definitions and extensions found in the document.
	local typeDefs: Array<any> = {} -- ROBLOX FIXME: use `TypeDefinitionNode` type
	-- ROBLOX deviation: use Map type
	local typeExtensionsMap = Map.new()

	-- // New directives and types are separate because a directives and types can
	-- // have the same name. For example, a type named "skip".
	local directiveDefs: Array<any> = {} -- ROBLOX FIXME: use `DirectiveDefinitionNode` type

	local schemaDef
	-- // Schema extensions are collected which may add additional operation types.
	local schemaExtensions: Array<any> = {} -- ROBLOX FIXME: use `SchemaExtensionNode` type

	for _, def in ipairs(documentAST.definitions) do
		if def.kind == Kind.SCHEMA_DEFINITION then
			schemaDef = def
		elseif def.kind == Kind.SCHEMA_EXTENSION then
			table.insert(schemaExtensions, def)
		elseif isTypeDefinitionNode(def) then
			table.insert(typeDefs, def)
		elseif isTypeExtensionNode(def) then
			local extendedTypeName = def.name.value
			-- ROBLOX deviation: use Map type
			local existingTypeExtensions = typeExtensionsMap:get(extendedTypeName)
			typeExtensionsMap:set(
				extendedTypeName,
				(function()
					if existingTypeExtensions then
						return Array.concat(existingTypeExtensions, { def })
					else
						return { def }
					end
				end)()
			)
		elseif def.kind == Kind.DIRECTIVE_DEFINITION then
			table.insert(directiveDefs, def)
		end
	end

	-- // If this document contains no new types, extensions, or directives then
	-- // return the same unmodified GraphQLSchema instance.
	if
		-- ROBLOX deviation: use Map type
		#typeExtensionsMap:keys() == 0
		and #typeDefs == 0
		and #directiveDefs == 0
		and #schemaExtensions == 0
		and schemaDef == nil
	then
		return schemaConfig
	end

	-- ROBLOX deviation: the rest of this function statements have been moved after
	-- the function declarations, because they are called within this scope, we can't
	-- pre-declare them like it's usually done. We still need to pre-declare some
	-- functions in relation to each other, and that is safe to do
	-- ROBLOX deviation: use Map type
	local typeMap = Map.new()

	-- ROBLOX deviation: pre-declare variables
	local replaceNamedType
	local extendArg
	local extendField
	local extendScalarType
	local extendObjectType
	local extendInterfaceType
	local extendUnionType
	local extendEnumType
	local extendInputObjectType
	local buildInputFieldMap
	local buildEnumValueMap
	local buildInterfaces
	local buildUnionTypes
	local getNamedType
	local buildArgumentMap
	local buildFieldMap

	-- // Below are functions used for producing this schema that have closed over
	-- // this scope and have access to the schema, cache, and newly defined types.

	local function replaceType(type_)
		if isListType(type_) then
			-- // $FlowFixMe[incompatible-return]
			return GraphQLList.new(replaceType(type_.ofType))
		end
		if isNonNullType(type_) then
			-- // $FlowFixMe[incompatible-return]
			return GraphQLNonNull.new(replaceType(type_.ofType))
		end
		return replaceNamedType(type_)
	end

	function replaceNamedType(type_)
		-- // Note: While this could make early assertions to get the correctly
		-- // typed values, that would throw immediately while type system
		-- // validation with validateSchema() will produce more actionable results.
		-- ROBLOX deviation: use Map type
		return typeMap:get(type_.name)
	end

	local function replaceDirective(directive: GraphQLDirective): GraphQLDirective
		local config = directive:toConfig()
		return GraphQLDirective.new(Object.assign(
			{},
			config,
			{ args = mapValue(config.args, extendArg) }
		))
	end

	local function extendNamedType(type_: GraphQLNamedType): GraphQLNamedType
		if isIntrospectionType(type_) or isSpecifiedScalarType(type_) then
			-- // Builtin types are not extended.
			return type_
		end
		if isScalarType(type_) then
			return extendScalarType(type_)
		end
		if isObjectType(type_) then
			return extendObjectType(type_)
		end
		if isInterfaceType(type_) then
			return extendInterfaceType(type_)
		end
		if isUnionType(type_) then
			return extendUnionType(type_)
		end
		if isEnumType(type_) then
			return extendEnumType(type_)
		end
		-- // istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
		if isInputObjectType(type_) then
			return extendInputObjectType(type_)
		end

		-- // istanbul ignore next (Not reachable. All possible types have been considered)
		invariant(false, "Unexpected type: " .. inspect(type_))
		-- ROBLOX deviation: Luau doesn't understand invariant is no-return
		return nil
	end

	function extendInputObjectType(
		type_: GraphQLInputObjectType
	): GraphQLInputObjectType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(config.name) or {}

		return GraphQLInputObjectType.new(Object.assign(
			{},
			config,
			{
				fields = function()
					return Object.assign(
						{},
						mapValue(config.fields, function(field)
							return Object.assign(
								{},
								field,
								{ type = replaceType(field.type) }
							)
						end),
						buildInputFieldMap(extensions)
					)
				end,
				extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
			}
		))
	end

	function extendEnumType(type_: GraphQLEnumType): GraphQLEnumType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(type_.name) or {}

		return GraphQLEnumType.new(
			Object.assign(
				{},
				config,
				{
					-- ROBLOX deviation: concat Maps instead of regular tables
					values = Map.new(Array.concat(config.values:entries(), buildEnumValueMap(extensions):entries())),
					extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
				}
			)
		)
	end

	function extendScalarType(type_: GraphQLScalarType): GraphQLScalarType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(config.name) or {}

		local specifiedByUrl = config.specifiedByUrl
		for _, extensionNode in ipairs(extensions) do
			specifiedByUrl = getSpecifiedByUrl(extensionNode) or specifiedByUrl
		end

		return GraphQLScalarType.new(Object.assign(
			{},
			config,
			{
				specifiedByUrl = specifiedByUrl,
				extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
			}
		))
	end

	function extendObjectType(
		type_: GraphQLObjectType
	): GraphQLObjectType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(config.name) or {}

		return GraphQLObjectType.new(Object.assign(
			{},
			config,
			{
				interfaces = function()
					return Array.concat(
					Array.map(type_:getInterfaces(), replaceNamedType),
					buildInterfaces(extensions)
				   )
				end,
				fields = function()
					return Object.assign(
						{},
						mapValue(config.fields, extendField),
						buildFieldMap(extensions)
					)
				end,
				extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
			}
		))
	end

	function extendInterfaceType(
		type_: GraphQLInterfaceType
	): GraphQLInterfaceType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(config.name) or {}

		return GraphQLInterfaceType.new(Object.assign(
			{},
			config,
			{
				interfaces = function()
					return Array.concat(
						Array.map(type_:getInterfaces(), replaceNamedType),
						buildInterfaces(extensions)
					)
				end,
				fields = function()
					return Object.assign(
						{},
						mapValue(config.fields, extendField),
						buildFieldMap(extensions)
					)
				end,
				extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
			}
		))
	end

	function extendUnionType(
		type_: GraphQLUnionType
	): GraphQLUnionType
		local config = type_:toConfig()
		-- ROBLOX deviation: use Map type
		local extensions = typeExtensionsMap:get(config.name) or {}

		return GraphQLUnionType.new(Object.assign(
			{},
			config,
			{
				types = function()
					return Array.concat(
						Array.map(type_:getTypes(), replaceNamedType),
						buildUnionTypes(extensions)
					)
				end,
				extensionASTNodes = Array.concat(config.extensionASTNodes, extensions),
			}
		))
	end

	function extendField(
		field: GraphQLFieldConfig<any, any>
	): GraphQLFieldConfig<any, any>
		return Object.assign(
			{},
			field,
			{
				type = replaceType(field.type),
				-- // $FlowFixMe[incompatible-call]
				args = mapValue(field.args, extendArg),
			}
		)
	end

	function extendArg(arg: GraphQLArgumentConfig)
		return Object.assign(
			{},
			arg,
			{ type = replaceType(arg.type) }
		)
	end

	local function getOperationTypes(
		nodes: Array<SchemaDefinitionNode | SchemaExtensionNode>
	): {
		query: GraphQLObjectType?,
		mutation: GraphQLObjectType?,
		subscription: GraphQLObjectType?,
	}
		local opTypes = {}
		for _, node in ipairs(nodes) do
			-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local operationTypesNodes = node.operationTypes or {}

			for _, operationType in ipairs(operationTypesNodes) do
				opTypes[operationType.operation] = getNamedType(operationType.type)
			end
		end

		-- // Note: While this could make early assertions to get the correctly
		-- // typed values below, that would throw immediately while type system
		-- // validation with validateSchema() will produce more actionable results.
		return opTypes
	end

	function getNamedType(node: NamedTypeNode): GraphQLNamedType
		local name = node.name.value
		-- ROBLOX deviation: use Map type
		local type_ = stdTypeMap[name] or typeMap:get(name)

		if type_ == nil then
			error(Error.new(("Unknown type: \"%s\"."):format(name)))
		end
		return type_
	end

	local function getWrappedType(node: TypeNode): GraphQLType
		if node.kind == Kind.LIST_TYPE then
			-- ROBLOX FIXME: remove cast to any
			local nodeAny: any = node
			return GraphQLList.new(getWrappedType(nodeAny.type))
		end
		if node.kind == Kind.NON_NULL_TYPE then
			-- ROBLOX FIXME: remove cast to any
			local nodeAny: any = node
			-- // $FlowFixMe[incompatible-call]
			return GraphQLNonNull.new(getWrappedType(nodeAny.type))
		end
		return getNamedType(node)
	end

	local function buildDirective(node: DirectiveDefinitionNode): GraphQLDirective
		local locations = Array.map(node.locations, function(location)
			return location.value
		end)

		-- ROBLOX FIXME: once Luau is able to refine types to support:
		-- `node.description and node.description.value`, then remove
		-- cast to any
		local anyNode: any = node
		return GraphQLDirective.new({
			name = node.name.value,
			description = anyNode.description and anyNode.description.value,
			locations = locations,
			isRepeatable = node.repeatable,
			args = buildArgumentMap(node.arguments),
			astNode = node,
		})
	end

	function buildFieldMap(
		nodes: Array<
			InterfaceTypeDefinitionNode
			| InterfaceTypeExtensionNode
			| ObjectTypeDefinitionNode
			| ObjectTypeExtensionNode
		>
	): GraphQLFieldConfigMap<any, any>
		local fieldConfigMap = {}
		for _, node in ipairs(nodes) do
			-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local nodeFields = node.fields or {}

			for _, field in ipairs(nodeFields) do
				fieldConfigMap[field.name.value] = {
					type = getWrappedType(field.type),
					description = field.description and field.description.value,
					--[[
					--	ROBLOX FIXME: we're losing the order of arguments in here.
					--  It works in JS because (for most Js engine implementations) Object.keys and Object.entries returns values in order of them being added
					--  but in Lua this is not the case
					-- 	ROBLOX FIXME: #142 https://github.com/Roblox/graphql-lua/issues/142
					--]]
					args = buildArgumentMap(field.arguments),
					deprecationReason = getDeprecationReason(field),
					astNode = field,
				}
			end
		end
		return fieldConfigMap
	end

	function buildArgumentMap(
		args: Array<InputValueDefinitionNode>?
	): GraphQLFieldConfigArgumentMap
		-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
		local argsNodes = args or {}

		local argConfigMap = {}
		for _, arg in ipairs(argsNodes) do
			-- // Note: While this could make assertions to get the correctly typed
			-- // value, that would throw immediately while type system validation
			-- // with validateSchema() will produce more actionable results.
			local type_: any = getWrappedType(arg.type)

			argConfigMap[arg.name.value] = {
				type = type_,
				description = arg.description and arg.description.value,
				defaultValue = valueFromAST(arg.defaultValue, type_),
				deprecationReason = getDeprecationReason(arg),
				astNode = arg,
			}
		end
		return argConfigMap
	end

	function buildInputFieldMap(
		nodes: Array<InputObjectTypeDefinitionNode | InputObjectTypeExtensionNode>
	): GraphQLInputFieldConfigMap
		local inputFieldMap = {}
		for _, node in ipairs(nodes) do
			-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local fieldsNodes = node.fields or {}

			for _, field in ipairs(fieldsNodes) do
				-- // Note: While this could make assertions to get the correctly typed
				-- // value, that would throw immediately while type system validation
				-- // with validateSchema() will produce more actionable results.
				local type_: any = getWrappedType(field.type)

				inputFieldMap[field.name.value] = {
					type = type_,
					description = field.description and field.description.value,
					defaultValue = valueFromAST(field.defaultValue, type_),
					deprecationReason = getDeprecationReason(field),
					astNode = field,
				}
			end
		end
		return inputFieldMap
	end

	function buildEnumValueMap(
		nodes: Array<EnumTypeDefinitionNode | EnumTypeExtensionNode>
	): GraphQLEnumValueConfigMap
		-- ROBLOX deviation: use Map to guarantee order
		local enumValueMap = Map.new()
		for _, node in ipairs(nodes) do
			-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local valuesNodes = node.values or {}

			for _, value in ipairs(valuesNodes) do
				enumValueMap:set(value.name.value, {
					description = value.description and value.description.value,
					deprecationReason = getDeprecationReason(value),
					astNode = value,
				})
			end
		end
		return enumValueMap
	end

	function buildInterfaces(
		nodes: Array<
			InterfaceTypeDefinitionNode
			| InterfaceTypeExtensionNode
			| ObjectTypeDefinitionNode
			| ObjectTypeExtensionNode
		>
	): Array<GraphQLInterfaceType>
		local interfaces = {}
		for _, node in ipairs(nodes) do
			-- // istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local interfacesNodes = node.interfaces or {}

			for _, type_ in ipairs(interfacesNodes) do
				-- // Note: While this could make assertions to get the correctly typed
				-- // values below, that would throw immediately while type system
				-- // validation with validateSchema() will produce more actionable
				-- // results.
				table.insert(interfaces, getNamedType(type_))
			end
		end
		return interfaces
	end

	function buildUnionTypes(
		nodes: Array<UnionTypeDefinitionNode | UnionTypeExtensionNode>
	): Array<GraphQLObjectType>
		local types = {}
		for _, node in ipairs(nodes) do
			-- istanbul ignore next (See: 'https://github.com/graphql/graphql-js/issues/2203')
			local typeNodes = node.types or {}

			for _, type_ in ipairs(typeNodes) do
				-- // Note: While this could make assertions to get the correctly typed
				-- // values below, that would throw immediately while type system
				-- // validation with validateSchema() will produce more actionable
				-- // results.
				table.insert(types, getNamedType(type_))
			end
		end
		return types
	end

	local function buildType(astNode: TypeDefinitionNode): GraphQLNamedType
		local name = astNode.name.value
		-- ROBLOX deviation: use Map type
		local extensionNodes = typeExtensionsMap:get(name) or {}

		local astNodeKind = astNode.kind
		if astNodeKind == Kind.OBJECT_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes
			local allNodes = Array.concat({ astNode }, extensionASTNodes)

			return GraphQLObjectType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				interfaces = function()
					return buildInterfaces(allNodes)
				end,
				fields = function()
					return buildFieldMap(allNodes)
				end,
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		elseif astNodeKind == Kind.INTERFACE_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes
			local allNodes = Array.concat({ astNode }, extensionASTNodes)

			return GraphQLInterfaceType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				interfaces = function()
					return buildInterfaces(allNodes)
				end,
				fields = function()
					return buildFieldMap(allNodes)
				end,
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		elseif astNodeKind == Kind.ENUM_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes
			local allNodes = Array.concat({ astNode }, extensionASTNodes)

			return GraphQLEnumType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				values = buildEnumValueMap(allNodes),
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		elseif astNodeKind == Kind.UNION_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes
			local allNodes = Array.concat({ astNode }, extensionASTNodes)

			return GraphQLUnionType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				types = function()
					return buildUnionTypes(allNodes)
				end,
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		elseif astNodeKind == Kind.SCALAR_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes

			return GraphQLScalarType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				specifiedByUrl = getSpecifiedByUrl(astNode),
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		elseif astNodeKind == Kind.INPUT_OBJECT_TYPE_DEFINITION then
			local extensionASTNodes: any = extensionNodes
			local allNodes = Array.concat({ astNode }, extensionASTNodes)

			return GraphQLInputObjectType.new({
				name = name,
				description = astNode.description and astNode.description.value,
				fields = function()
					return buildInputFieldMap(allNodes)
				end,
				astNode = astNode,
				extensionASTNodes = extensionASTNodes,
			})
		end

		-- // istanbul ignore next (Not reachable. All possible type definition nodes have been considered)
		invariant(false, "Unexpected type definition node: " .. inspect(astNode))
		-- ROBLOX deviation: no implicit return
		return nil
	end

	for _, existingType in ipairs(schemaConfig.types) do
		-- ROBLOX deviation: use Map type
		typeMap:set(existingType.name, extendNamedType(existingType))
	end

	for _, typeNode in ipairs(typeDefs) do
		local name = typeNode.name.value
		-- ROBLOX deviation: use Map type
		typeMap:set(name, stdTypeMap[name] or buildType(typeNode))
	end

	local operationTypes = Object.assign(
		{},
		{
			-- // Get the extended root operation types.
			query = schemaConfig.query and replaceNamedType(schemaConfig.query),
			mutation = schemaConfig.mutation and replaceNamedType(schemaConfig.mutation),
			subscription = schemaConfig.subscription and replaceNamedType(schemaConfig.subscription),
		},
		-- // Then, incorporate schema definition and all schema extensions.
		schemaDef and getOperationTypes({ schemaDef }) or {},
		getOperationTypes(schemaExtensions)
	)

	local description = nil
	if schemaDef ~= nil and schemaDef.description ~= nil then
		description = schemaDef.description.value
	end
	local assumeValid = false
	if options ~= nil and options.assumeValid ~= nil then
		assumeValid = options.assumeValid
	end
	-- // Then produce and return a Schema config with these types.
	local schemaExtension = Object.assign({}, { description = description }, operationTypes, {
		-- ROBLOX deviation: use Map type
		types = typeMap:values(),
		directives = Array.concat(
			Array.map(schemaConfig.directives, replaceDirective),
			Array.map(directiveDefs, buildDirective)
		),
		-- ROBLOX deviation: we can't remove a property by mapping it to `nil` in Lua
		-- so we have to manually remove it on the next statement.
		-- extensions = nil,
		astNode = schemaDef or schemaConfig.astNode,
		extensionASTNodes = Array.concat(schemaConfig.extensionASTNodes, schemaExtensions),
		assumeValid = assumeValid,
	})
	schemaExtension.extensions = nil
	return schemaExtension
end

stdTypeMap = keyMap(Array.concat(specifiedScalarTypes, introspectionTypes), function(type_)
	return type_.name
end)

-- /**
--  * Given a field or enum value node, returns the string value for the
--  * deprecation reason.
--  */
function getDeprecationReason(
	node:
	EnumValueDefinitionNode
    | FieldDefinitionNode
    | InputValueDefinitionNode
): string?
	local deprecated = getDirectiveValues(GraphQLDeprecatedDirective, node)
	return deprecated and deprecated.reason
end

-- /**
--  * Given a scalar node, returns the string value for the specifiedByUrl.
--  */
function getSpecifiedByUrl(
	node: ScalarTypeDefinitionNode | ScalarTypeExtensionNode
): string?
	local specifiedBy = getDirectiveValues(GraphQLSpecifiedByDirective, node)
	return specifiedBy and specifiedBy.url
end

return {
	extendSchema = extendSchema,
	extendSchemaImpl = extendSchemaImpl,
}
