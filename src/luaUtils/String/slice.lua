return function(str, startIndexStr, lastIndexStr)

	local strLen = utf8.len(str)

	if startIndexStr < 0 then
		-- then start index is negative
		startIndexStr = strLen + startIndexStr
	end

	if startIndexStr > strLen then
		return ""
	end

	-- if no last index length set, go to str length + 1
	lastIndexStr = lastIndexStr or strLen + 1

	if lastIndexStr > strLen then
		lastIndexStr = strLen + 1
	end

	local startIndexByte = utf8.offset(str, startIndexStr)
	-- get char length of charset retunred at offset
	local lastIndexByte = utf8.offset(str, lastIndexStr) - 1

	return string.sub(str, startIndexByte, lastIndexByte)

end
