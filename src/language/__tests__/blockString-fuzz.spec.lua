-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/blockString-fuzz.js

return function()

	local language = script.Parent.Parent
	local src = language.Parent

	local dedent = require(src.__testUtils__.dedent)
	local inspectStr = require(src.__testUtils__.inspectStr)
	local genFuzzStrings = require(src.__testUtils__.genFuzzStrings)

	local invariant = require(src.jsutils.invariant)

	local Lexer = require(language.lexer).Lexer
	local Source = require(language.source).Source
	local printBlockString = require(language.blockString).printBlockString

	function lexValue(str: string)
		local lexer = Lexer.new(Source.new(str))
		local value = lexer.advance().value

		invariant(lexer.advance().kind == "<EOF>", "Expected EOF")
		return value
	end

	describe("printBlockString", function()
		it("correctly print random strings", function()
			for fuzzStr in genFuzzStrings({
				allowedChars = { "\n", "\t", " ", "\"", "a", "\\" },
				maxLength = 7,
			}) do
				local testStr = "\"\"\"" .. fuzzStr .. "\"\"\""

				local testValue
				local _ok = pcall(function()
					testValue = lexValue(testStr)
				end)
				if not _ok then
					-- skip invalid values
					continue
				end

				invariant(typeof(testValue) == "string")

				local printedValue = lexValue(printBlockString(testValue))

				invariant(
					testValue == printedValue,
					dedent("Expected lexValue(printBlockString(" .. inspectStr(testValue) .. "))\n" .. "to equal " .. inspectStr(testValue) .. "\n" .. "but got  " .. inspectStr(printedValue))
				)

				local printedMultilineString = lexValue(printBlockString(testValue, " ", true))

				invariant(
					testValue == printedMultilineString,
					dedent("Expected lexValue(printBlockString(" .. inspectStr(testValue) .. ", ' ', true))\n" .. "to equal " .. inspectStr(testValue) .. "\n" .. "but got  " .. inspectStr(printedMultilineString))

				)

			end

		end)
	end)
end
