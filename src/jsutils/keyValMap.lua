-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/keyValMap.js
local ObjMapModule = require(script.Parent.ObjMap)
type ObjMap = ObjMapModule.ObjMap

--[[
 * Creates a keyed JS object from an array, given a function to produce the keys
 * and a function to produce the values from each item in the array.
 *
 *     const phoneBook = [
 *       { name: 'Jon', num: '555-1234' },
 *       { name: 'Jenny', num: '867-5309' }
 *     ]
 *
 *     // { Jon: '555-1234', Jenny: '867-5309' }
 *     const phonesByName = keyValMap(
 *       phoneBook,
 *       entry => entry.name,
 *       entry => entry.num
 *     )
 *
 ]]

local function keyValMap(list: Array<any>, keyFn: (any) -> string, valFn: (any) -> any): ObjMap<any>
	local map = {}
	for i = 1, #list do
		local item = list[i]
		map[keyFn(item)] = valFn(item)
	end
	return map
end

return {
	keyValMap = keyValMap,
}
