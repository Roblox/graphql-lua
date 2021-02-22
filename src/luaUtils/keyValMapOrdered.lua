type Array<T> = { [number]: T }

local Map = require(script.Parent.Parent.luaUtils.Map)
type Map<T, V> = Map.Map<T, V>

--[[
 * Creates an ordered keyed map from an array, given a function to produce the keys
 * and a function to produce the values from each item in the array.
 *
 *     const phoneBook = [
 *       { name: 'Jon', num: '555-1234' },
 *       { name: 'Jenny', num: '867-5309' }
 *     ]
 *
 *     // Map.new(
 *	   //   {'John', '555-1234'},
 *     //   {'Jenny', '867-5309'}
 *     // )
 *     const phonesByName = keyValMapOrdered(
 *       phoneBook,
 *       entry => entry.name,
 *       entry => entry.num
 *     )
 *
 ]]

local function keyValMapOrdered(
	list: Array<any>,
	keyFn: (any) -> string,
	valFn: (any) -> any
): Map<string, any>
	local map = Map.new()
	for i = 1, #list do
		local item = list[i]
		map:set(keyFn(item), valFn(item))
	end
	return map
end

return {
	keyValMapOrdered = keyValMapOrdered,
}
