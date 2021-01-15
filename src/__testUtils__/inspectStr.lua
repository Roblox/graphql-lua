-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/inspectStr.js

local HttpService = game:GetService("HttpService")

local function replaceLeadingQuote(str)
	str = string.gsub(str, "\n\"", "\n`")
	if str.sub(str, 1, 1) == "\"" then
		return "`" .. string.sub(str, 2)
	end
	return str
end

local function replaceTrailingQuote(str)
	str = string.gsub(str, "\"\n", "`\n")
	if str.sub(str, -1) == "\"" then
		return string.sub(str, 1, -2) .. "`"
	end
	return str
end

-- /**
--  * Special inspect function to produce readable string literal for error messages in tests
--  */
return function(str: string): string
    if str == nil then
		return "nil"
	end
	str = HttpService:JSONEncode(str)
	str = replaceTrailingQuote(replaceLeadingQuote(str))
	str = string.gsub(str, "\\\"", "\"")
	str = string.gsub(str, "\\\\", "\\")
	return str
end
