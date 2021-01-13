return function(str, _startIndex, _lastIndex)
	local startIndex = _startIndex
	if _startIndex < 0 then
		-- then start index is negative
		startIndex = #str + _startIndex
	end

	local strLen = #str
	local lastIndex = _lastIndex or strLen + 1

	local sliced = ""

	local counter = startIndex

	for i = startIndex or 1, strLen do
		if counter < lastIndex then
			sliced = sliced .. string.sub(str, i, i)
		end
		counter = counter + 1
	end

	return sliced
end
