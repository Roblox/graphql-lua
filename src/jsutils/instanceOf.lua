-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/instanceOf.js

local function instanceOf(subject, super)
	if subject == nil then
		return false
	end

	if typeof(subject) ~= "table" or typeof(super) ~= "table" then
		return false
	end

	if super.new ~= nil and subject.new == super.new then
		return true
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
return function(instance: any, type_: any)
	-- deviation: FIXME: Can we expose something from JSPolyfill that
	-- will let us verify that this is specifically the Error object
	-- defined there?

	return instanceOf(instance, type_)
end
