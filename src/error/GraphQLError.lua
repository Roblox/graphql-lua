-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/error/GraphQLError.js

-- directory
local srcWorkspace = script.Parent.Parent
local languageWorkspace = srcWorkspace.language

-- require
local getLocation = require(languageWorkspace.location).getLocation
local printLocationIndex = require(languageWorkspace.printLocation)
local printLocation = printLocationIndex.printLocation
local printSourceLocation = printLocationIndex.printSourceLocation

-- lua helpers & polyfills
local isObjectLike = require(srcWorkspace.jsutils.isObjectLike)
local symbols = require(srcWorkspace.polyfill.symbols)
local SYMBOL_TO_STRING_TAG = symbols.SYMBOL_TO_STRING_TAG
local Array = require(srcWorkspace.Parent.Packages.LuauPolyfill).Array
local Error = require(srcWorkspace.luaUtils.Error)

-- deviation: pre-declare functions
local printError

local GraphQLError = setmetatable({}, { __index = Error })
GraphQLError.__index = GraphQLError
GraphQLError.__tostring = function(self)
	return printError(self)
end

function GraphQLError.new(
	message: string,
	nodes,
	source,
	positions: Array<number>,
	path: Array<number | string>,
	originalError,
	extensions
)

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

	-- REF: GraphQLError.js:104
	local _positions = positions
	if not _positions and _nodes then
		_positions = Array.reduce(_nodes, function(list, node)
			if node.loc ~= nil then
				table.insert(list, node.loc.start)
			end
			return list
		end)
	end
	if _positions ~= nil and #_positions == 0 then
		_positions = nil
	end

	-- REF: GraphQLError.js:117
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
		end)
	end

	-- REF: GraphQLError.js:129
	local _extensions = extensions
	if _extensions == nil and originalError ~= nil then
		local originalExtensions = originalError.originalExtensions
		if isObjectLike(originalExtensions) then
			_extensions = originalExtensions
		end
	end

	local self = Error.new(message)
	-- REF: GraphQLError.js:137
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

	-- getter for symbol to string
	GraphQLError[SYMBOL_TO_STRING_TAG] = "Object"

	return setmetatable(self, GraphQLError)
end

function GraphQLError:toString(): string
	return printError(self)
end

function printError(error)
	local output = error.message

	if error.nodes ~= nil then
		local lengthOfNodes = #error.nodes
		for i = 1, lengthOfNodes, 1 do
			local node = error.nodes[i]
			if node.loc ~= nil then
				output = output .. "\n\n" .. printLocation(node.loc)
			end
		end
	elseif error.source ~= nil and error.locations ~= nil then
		local lengthOfLocations = #error.locations
		for i = 1, lengthOfLocations, 1 do
			local location = error.locations[i]
			output = output .. "\n\n" .. printSourceLocation(error.source, location)
		end
	end

	return output
end

return {
	printError = printError,
	GraphQLError = GraphQLError,
}
