return function()
	local jsutils = script.Parent.Parent
	local didYouMean = require(jsutils.didYouMean)

	describe('didYouMean', function()
		it('Does accept an empty list', function()
			expect(didYouMean({})).to.equal('')
		end)

		it('Handles single suggestion', function()
			expect(didYouMean({'A'})).to.equal(' Did you mean "A"?')
		end)

		it('Handles two suggestions', function()
			expect(didYouMean({'A', 'B'})).to.equal(' Did you mean "A" or "B"?')
		end)

		it('Handles multiple suggestions', function()
			expect(didYouMean({'A', 'B', 'C'})).to.equal(
				' Did you mean "A", "B", or "C"?'
			)
		end)

		it('Limits to five suggestions', function()
			expect(didYouMean({'A', 'B', 'C', 'D', 'E', 'F'})).to.equal(
				' Did you mean "A", "B", "C", "D", or "E"?'
			)
		end)

		it('Adds sub-message', function()
			expect(didYouMean('the letter', {'A'})).to.equal(
				' Did you mean the letter "A"?'
			)
		end)
	end)
end
