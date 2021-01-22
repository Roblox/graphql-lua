local NaN = 0 / 0

-- js  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/charCodeAt
-- lua http://www.lua.org/manual/5.4/manual.html#pdf-utf8.codepoint
return function(str, pos): number
	if pos > utf8.len(str) then
		return NaN
	end


	local offset = utf8.offset(str, pos)
	local value = utf8.codepoint(str, offset, offset)

	if value == nil then
		return NaN
	end

	return value
end
