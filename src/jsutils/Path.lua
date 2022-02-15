-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/Path.js
local rootWorkspace = script.Parent.Parent.Parent
local LuauPolyfill = require(rootWorkspace.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>

export type Path = {
	prev: Path?,
	key: string | number,
	typename: string?,
}

local exports = {}

function exports.addPath(prev: Path, key: string | number, typename: string?): Path
	return {
		prev = prev,
		key = key,
		typename = typename,
	}
end

function exports.pathToArray(path: Path?): Array<string | number>
	local flattened = {}
	local curr = path
	while curr do
		table.insert(flattened, curr.key)
		curr = curr.prev
	end
	-- deviation: FIXME: once we have a dependency to the
	-- polyfills implementations, we should use Array.reverse.
	-- return Array.reverse(flattened)
	local length = #flattened
	local reversed = {}
	for i = length, 1, -1 do
		table.insert(reversed, flattened[i])
	end
	return reversed
end

return exports
