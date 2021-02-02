-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/separateOperations.js
local ObjMapModule = require(script.Parent.Parent.jsutils.ObjMap) -- type { ObjMap } from '../jsutils/ObjMap';
type ObjMap<T> = ObjMapModule.ObjMap<T>

-- ROBLOX deviation: Common types
type Array<T> = { [number]: T }
type Set<T> = { [T]: boolean }


local srcWorkspace = script.Parent.Parent
local PackagesWorkspace = srcWorkspace.Parent.Packages

local Kind = require(srcWorkspace.language.kinds).Kind
local LuauPolyfill = require(PackagesWorkspace.LuauPolyfill)
local visit = require(srcWorkspace.language.visitor).visit

local Array = LuauPolyfill.Array

local collectDependencies
local collectTransitiveDependencies

--[[**
	* separateOperations accepts a single AST document which may contain many
	* operations and fragments and returns a collection of AST documents each of
	* which contains a single operation as well the fragment definitions it
	* refers to.
	*]]
local function separateOperations(documentAST)
	local operations = {}
	local depGraph = {}

	-- Populate metadata and build a dependency graph
	for _, definitionNode in pairs(documentAST.definitions) do
		local definitionNodeKind = definitionNode.kind
		if definitionNodeKind == Kind.OPERATION_DEFINITION then
			table.insert(operations, definitionNode)
		elseif definitionNodeKind == Kind.FRAGMENT_DEFINITION then
			depGraph[definitionNode.name.value] = collectDependencies(definitionNode.selectionSet)
		end
	end

	-- For each operation, produce a new synthesized AST which includes only what
	-- is necessary for completing that operation.
	local separatedDocumentASTs = {}
	for _, operation in pairs(operations) do
		local dependencies: Set<string> = {}

		for _, fragmentName in pairs(collectDependencies(operation.selectionSet)) do
			collectTransitiveDependencies(dependencies, depGraph, fragmentName)
		end

		-- Provides the empty string for anonymous operations
		local operationName = operation.name and operation.name.value or ""

		-- The list of definition nodes to be included for this operation, sorted
		-- to retain the same order as the original document.
		separatedDocumentASTs[operationName] = {
			kind = Kind.DOCUMENT,
			definitions = Array.filter(documentAST.definitions, function(node)
				return node == operation
					or (node.kind == Kind.FRAGMENT_DEFINITION
					and dependencies[node.name.value])
			end),
		}
	end

	return separatedDocumentASTs
end

type DepGraph = ObjMap<Array<string>>

-- From a dependency graph, collects a list of transitive dependencies by
-- recursing through a dependency graph.
function collectTransitiveDependencies(
	collected: Set<string>,
	depGraph: DepGraph,
	fromName: string
)
	if not collected[fromName] then
		collected[fromName] = true

		local immediateDeps = depGraph[fromName]
		if immediateDeps ~= nil then
			for key, toName in pairs(immediateDeps) do
				collectTransitiveDependencies(collected, depGraph, toName)
			end
		end
	end
end

function collectDependencies(selectionSet): Array<string>
	local dependencies = {}

	visit(selectionSet, {
		FragmentSpread = function(self, node)
			table.insert(dependencies, node.name.value)
		end,
	})

	return dependencies

end

return {
	separateOperations = separateOperations,
}
