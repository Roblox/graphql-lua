-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/instanceOf.js

local function instanceOf(subject, super)
	if subject == nil then
		return false
	end

	local mt = getmetatable(subject)
	while true do
		if mt == nil then
			return false
		end
		if mt.__index == super then
			return true
		end

		local prevMT = mt
		mt = getmetatable(mt.__index)
		if prevMT == mt then
			return false
		end
	end
end

-- return public facing API and allow recursion internally
return function(instance: any, type: any)
	-- deviation: FIXME: Can we expose something from JSPolyfill that
	-- will let us verify that this is specifically the Error object
	-- defined there?

	return instanceOf(instance, type)
end
