-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/toObjMap.js
return function(obj)
	local map = {}
	for key, value in pairs(obj) do
		map[key] = value
	end
	return map
end
