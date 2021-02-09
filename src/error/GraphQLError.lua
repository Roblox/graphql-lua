-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/error/GraphQLError.js
type Array<T> = { [number]: T }

-- ROBLOX directory
local srcWorkspace = script.Parent.Parent
local languageWorkspace = srcWorkspace.language

local _sourceModule = require(languageWorkspace.source)
type Source = _sourceModule.Source

-- require
local locationModule = require(languageWorkspace.location)
type SourceLocation = locationModule.SourceLocation
local getLocation = locationModule.getLocation
local printLocationIndex = require(languageWorkspace.printLocation)
local printLocation = printLocationIndex.printLocation
local printSourceLocation = printLocationIndex.printSourceLocation

-- lua helpers & polyfills
local isObjectLike = require(srcWorkspace.jsutils.isObjectLike).isObjectLike
local Array = require(srcWorkspace.Parent.Packages.LuauPolyfill).Array
local Error = require(srcWorkspace.luaUtils.Error)

-- ROBLOX deviation: pre-declare functions
local printError

-- ROBLOX deviation: type not implemented yet
type ASTNode = any
type Error = any

local GraphQLError = setmetatable({}, { __index = Error })
GraphQLError.__index = GraphQLError
GraphQLError.__tostring = function(self)
	return printError(self)
end

export type GraphQLError = {
	-- /**
	--  * A message describing the Error for debugging purposes.
	--  *
	--  * Enumerable, and appears in the result of JSON.stringify().
	--  *
	--  * Note: should be treated as readonly, despite invariant usage.
	--  */
	message: string,

	-- /**
	--  * An array of { line, column } locations within the source GraphQL document
	--  * which correspond to this error.
	--  *
	--  * Errors during validation often contain multiple locations, for example to
	--  * point out two things with the same name. Errors during execution include a
	--  * single location, the field which produced the error.
	--  *
	--  * Enumerable, and appears in the result of JSON.stringify().
	--  */
	locations: Array<SourceLocation> | nil,

	-- /**
	--  * An array describing the JSON-path into the execution response which
	--  * corresponds to this error. Only included for errors during execution.
	--  *
	--  * Enumerable, and appears in the result of JSON.stringify().
	--  */
	path: Array<string | number> | nil,

	-- /**
	--  * An array of GraphQL AST Nodes corresponding to this error.
	--  */
	nodes: Array<ASTNode> | nil,

	-- /**
	--  * The source GraphQL document for the first location of this error.
	--  *
	--  * Note that if this Error represents more than one node, the source may not
	--  * represent nodes after the first node.
	--  */
	source: Source | nil,

	-- /**
	--  * An array of character offsets within the source GraphQL document
	--  * which correspond to this error.
	--  */
	positions: Array<number> | nil,

	-- /**
	--  * The original error thrown from a field resolver during execution.
	--  */
	originalError: Error?,

	-- /**
	--  * Extension fields to add to the formatted error.
	--  */
	extensions: { [string]: any } | nil,
}

function GraphQLError.new(
	message: string,
	nodes,
	source,
	positions: Array<number>,
	path: Array<string | number>,
	originalError,
	extensions
): GraphQLError

	-- Compute list of blame nodes.
	local _nodes = nil
	if Array.isArray(nodes) then
		if #nodes ~= 0 then
			_nodes = nodes
		end
	elseif nodes ~= nil then
		_nodes = { nodes }
	end

	-- Compute locations in the source for the given nodes/positions.
	local _source = source
	if _source == nil and _nodes ~= nil then
		_source = _nodes[1].loc ~= nil and _nodes[1].loc.source or nil
	end

	local _positions = positions
	if _positions == nil and _nodes ~= nil then
		_positions = Array.reduce(_nodes, function(list, node)
			if node.loc ~= nil then
				table.insert(list, node.loc.start)
			end
			return list
		end, {})
	end
	if _positions ~= nil and #_positions == 0 then
		_positions = nil
	end

	local _locations
	if positions ~= nil and source ~= nil then
		_locations = Array.map(positions, function(pos)
			return getLocation(source, pos)
		end)
	elseif _nodes ~= nil then
		_locations = Array.reduce(_nodes, function(list, node)
			if node.loc ~= nil then
				table.insert(list, getLocation(node.loc.source, node.loc.start))
			end
			return list
		end, {})
	end

	local _extensions = extensions
	if _extensions == nil and originalError ~= nil then
		local originalExtensions = originalError.originalExtensions
		if isObjectLike(originalExtensions) then
			_extensions = originalExtensions
		end
	end

	local self = Error.new(message)
	self.name = "GraphQLError"
	self.locations = _locations
	self.path = path
	self.nodes = _nodes
	self.source = _source
	self.positions = _positions
	self.originalError = originalError
	self.extensions = _extensions

	if (originalError and originalError.stack) ~= nil then
		self.stack = originalError.stack
	end

	-- if Error.captureStackTrace ~= nil then
	-- 	Error.captureStackTrace(self, GraphQLError)
	-- else
	-- 	self.stack = Error.new().stack
	-- end

	-- FIXME: workaround to not break chai comparisons, should be remove in v16
	-- ROBLOX deviation: remove already deprecated API only used for JS tests

	return setmetatable(self, GraphQLError)
end

function GraphQLError:toString(): string
	return printError(self)
end

function printError(error_)
	local output = error_.message

	if error_.nodes ~= nil then
		local lengthOfNodes = #error_.nodes
		for i = 1, lengthOfNodes, 1 do
			local node = error_.nodes[i]
			if node.loc ~= nil then
				output = output .. "\n\n" .. printLocation(node.loc)
			end
		end
	elseif error_.source ~= nil and error_.locations ~= nil then
		local lengthOfLocations = #error_.locations
		for i = 1, lengthOfLocations, 1 do
			local location = error_.locations[i]
			output = output .. "\n\n" .. printSourceLocation(error_.source, location)
		end
	end

	return output
end

return {
	printError = printError,
	GraphQLError = GraphQLError,
}
