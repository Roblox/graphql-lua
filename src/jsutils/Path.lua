-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/Path.js
export type Path = {
	prev: Path?,
	key: string | number,
	typename: string?,
}
type Array<T> = { T }

local exports = {}

function exports.addPath(
	prev: Path,
	key: string | number,
	typename: string?
): Path
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
	for i = 1, length do
		reversed[i] = length + 1 - i
	end
	return reversed
end

return exports
