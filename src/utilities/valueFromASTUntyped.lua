-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/valueFromASTUntyped.js
local srcWorkspace = script.Parent.Parent
local jsUtilsWorkspace = srcWorkspace.jsutils
local languageWorkspace = srcWorkspace.language

local ObjMapModule = require(jsUtilsWorkspace.ObjMap)
type ObjMap<T> = ObjMapModule.ObjMap<T>

local inspect = require(jsUtilsWorkspace.inspect).inspect
local invariant = require(jsUtilsWorkspace.invariant).invariant
local keyValMap = require(jsUtilsWorkspace.keyValMap).keyValMap

local Kind = require(languageWorkspace.kinds).Kind

-- ROBLOX deviation: bring in polyfills
local Array = require(srcWorkspace.Parent.Packages.LuauPolyfill).Array

--[[**
 * Produces a JavaScript value given a GraphQL Value AST.
 *
 * Unlike `valueFromAST()`, no type is provided. The resulting JavaScript value
 * will reflect the provided GraphQL value AST.
 *
 * | GraphQL Value        | JavaScript Value |
 * | -------------------- | ---------------- |
 * | Input Object         | Object           |
 * | List                 | Array            |
 * | Boolean              | Boolean          |
 * | String / Enum        | String           |
 * | Int / Float          | Number           |
 * | Null                 | null             |
 *
 *]]

local function valueFromASTUntyped(valueNode, variables: ObjMap<any>): any
	if valueNode.kind == Kind.NULL then
		return nil
	elseif valueNode.kind == Kind.INT then
		return tonumber(valueNode.value, 10)
	elseif valueNode.kind == Kind.FLOAT then
		return tonumber(valueNode.value)

	elseif valueNode.kind == Kind.STRING or valueNode.kind == Kind.ENUM or valueNode.kind == Kind.BOOLEAN then
		return valueNode.value

	elseif valueNode.kind == Kind.LIST then

		return Array.map(valueNode.values, function(node)
			return valueFromASTUntyped(node, variables)
		end)
	elseif valueNode.kind == Kind.OBJECT then
		return keyValMap(valueNode.fields, function(field)
			return field.name.value
		end, function(field)
			return valueFromASTUntyped(field.value, variables)
		end)
	elseif valueNode.kind == Kind.VARIABLE then
		return variables and variables[valueNode.name.value]
	end

	-- istanbul ignore next (Not reachable. All possible value nodes have been considered)
	invariant(false, "Unexpected value node: " + inspect(valueNode))
	-- ROBLOX deviation: should never reach here, but need to convince analyzer
	error("Unexpected value node: " + inspect(valueNode))
end

return {
	valueFromASTUntyped = valueFromASTUntyped,
}