return function(str, patternTable, init)
	-- loop through all options in patern patternTable

	local matches = {}
	for _, value in pairs(patternTable) do
		local i = string.find(str, value, init)
		if i ~= nil then -- confirm truthy
			local match = {
				index = i,
				match = value,
			}
			table.insert(matches, match)
		end
	end

	-- if no matches, return nil
	if #matches == 0 then
		return nil
	end

	-- find the first matched index (after the init param)
	-- for each, if we get a hit, return the earliest index and matched term

	local firstMatch
	for _, value in pairs(matches) do
		-- load first condition
		if firstMatch == nil then
			firstMatch = value
		end
		-- identify if current match comes before first match
		if value.index < firstMatch.index then
			firstMatch = value
		end
	end

	-- return first match
	return firstMatch
end
