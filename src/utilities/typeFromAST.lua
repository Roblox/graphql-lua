-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/typeFromAST.js

local srcWorkspace = script.Parent.Parent

local inspect = require(srcWorkspace.jsutils.inspect).inspect
local invariant = require(srcWorkspace.jsutils.invariant).invariant
local Kind = require(srcWorkspace.language.kinds).Kind
local definitionImport = require(srcWorkspace.type.definition)
local GraphQLList = definitionImport.GraphQLList
local GraphQLNonNull = definitionImport.GraphQLNonNull

--[[*
--  * Given a Schema and an AST node describing a type, return a GraphQLType
--  * definition which applies to that type. For example, if provided the parsed
--  * AST node for `[User]`, a GraphQLList instance will be returned, containing
--  * the type called "User" found in the schema. If a type called "User" is not
--  * found in the schema, then undefined will be returned.
--  *]]
local function typeFromAST(schema, typeNode)
	local innerType
	if typeNode.kind == Kind.LIST_TYPE then
		innerType = typeFromAST(schema, typeNode.type)
		return innerType and GraphQLList.new(innerType)
	end
	if typeNode.kind == Kind.NON_NULL_TYPE then
		innerType = typeFromAST(schema, typeNode.type)
		return innerType and GraphQLNonNull.new(innerType)
	end
	-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
	if typeNode.kind == Kind.NAMED_TYPE then
		return schema:getType(typeNode.name.value)
	end

	-- istanbul ignore next (Not reachable. All possible type nodes have been considered)
	invariant(false, "Unexpected type node: " .. inspect(typeNode))
	return -- ROBLOX deviation: no implicit returns
end

return {
	typeFromAST = typeFromAST,
}
