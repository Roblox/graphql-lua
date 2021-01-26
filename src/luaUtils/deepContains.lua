local function deepContains(a: any, b: any)
	if typeof(a) ~= typeof(b) then
		local message = ("{1}: value of type '%s'\n{2}: value of type '%s'"):format(
			typeof(a),
			typeof(b)
		)
		return false, message
	end

	if a == b then
		return true
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in pairs(b) do
			visitedKeys[key] = true
			local success, innerMessage = deepContains(value, a[key])
			if not success then
				local message = innerMessage
					:gsub("{1}", ("{1}[%s]"):format(tostring(key)))
					:gsub("{2}", ("{2}[%s]"):format(tostring(key)))

				return false, message
			end
		end
		return true
	end

	local message = string.format("{1} (%s) ~= {2} (%s)", tostring(a), tostring(b))
	return false, message
end

return deepContains
