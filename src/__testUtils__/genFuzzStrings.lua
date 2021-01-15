-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/genFuzzStrings.js

-- /**
--  * Generator that produces all possible combinations of allowed characters.
--  * options: {
--  * 	allowedChars: { string },
--  * 	maxLength: number,
--  * }
--  */
return function(options)
	local function getFuzzStrings()
		local allowedChars = options.allowedChars
		local maxLength = options.maxLength
		local numAllowedChars = #allowedChars

		local numCombinations = 0

		for length = 1, maxLength do
			numCombinations += numAllowedChars ^ length
		end

		coroutine.yield("") -- special case for empty string

		for combination = 0, numCombinations - 1 do
			local permutation = ""

			local leftOver = combination
			while leftOver >= 0 do
				local reminder = leftOver % numAllowedChars;
				permutation = allowedChars[reminder + 1] .. permutation;
				leftOver = (leftOver - reminder) / numAllowedChars - 1;
			end
			coroutine.yield(permutation)
		end
	end

	return {
		next = coroutine.wrap(getFuzzStrings),
	}
end
