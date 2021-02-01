-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/toObjMap.js
local ObjMapModule = require(script.Parent.ObjMap)
type ObjMap<T> = ObjMapModule.ObjMap<T>

local function toObjMap(obj): ObjMap<any>
	local map = {}
	for key, value in pairs(obj) do
		map[key] = value
	end
	return map
end

return {
	toObjMap = toObjMap,
}
