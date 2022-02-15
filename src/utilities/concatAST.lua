-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/concatAST.js

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>

--[[*
--  * Provided a collection of ASTs, presumably each from different files,
--  * concatenate the ASTs together into batched AST, useful for validating many
--  * GraphQL source files which together represent one conceptual application.
--  *]]
function concatAST(documents: Array<any>)
	local definitions = {}
	for _, doc in ipairs(documents) do
		definitions = Array.concat(definitions, doc.definitions)
	end
	return { kind = "Document", definitions = definitions }
end

return {
	concatAST = concatAST,
}
