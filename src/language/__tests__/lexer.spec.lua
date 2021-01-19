-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/language/__tests__/lexer-test.js

return function()
	local language = script.Parent.Parent
	local src = language.Parent

	local inspect = require(src.jsutils.inspect)
	local lexerExport = require(language.lexer)
	local dedent = require(src.__testUtils__.dedent)
	local sourceExport = require(language.source)
	local tokenKindExport = require(language.tokenKind)
	local Array = require(src.luaUtils.Array)

	local Lexer = lexerExport.Lexer
	local Source = sourceExport.Source
	local TokenKind = tokenKindExport.TokenKind

	local lexOne = function(str)
		local lexer = Lexer.new(Source.new(str))
		return lexer:advance()
	end

	local lexSecond = function(str)
		local lexer = Lexer.new(Source.new(str))

		lexer:advance()
		return lexer:advance()
	end

	local expectSyntaxError = function(text)
		local lexSecondRes = function()
			return lexSecond(text)
		end
		local _ok, thrownError = pcall(lexSecondRes)
		expect(_ok).to.equal(false)
		return thrownError
	end

	describe("Lexer", function()
		it("disallows uncommon control characters", function()
			expect(expectSyntaxError("\007")).toObjectContain({
				message = "Syntax Error: Cannot contain the invalid character \"\\u0007\".",
				locations = { { column = 1, line = 1 } },
			})
		end)

		itSKIP("accepts BOM header", function()
			expect(lexOne("\\uFEFF foo")).toArrayContains({
				kind = TokenKind.NAME,
				start = 2,
				_end = 5,
				value = "foo",
			})
		end)

		it("tracks line breaks", function()
			expect(lexOne("foo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 1,
				_end = 4,
				line = 1,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\nfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 2,
				_end = 5,
				line = 2,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\rfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 2,
				_end = 5,
				line = 2,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\r\nfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 3,
				_end = 6,
				line = 2,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\n\rfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 3,
				_end = 6,
				line = 3,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\r\r\n\nfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 5,
				_end = 8,
				line = 4,
				column = 1,
				value = "foo",
			})
			expect(lexOne("\n\n\r\rfoo")).toObjectContain({
				kind = TokenKind.NAME,
				start = 5,
				_end = 8,
				line = 5,
				column = 1,
				value = "foo",
			})
		end)

		it("records line and column", function()
			expect(lexOne("\n \r\n \r  foo\n")).toObjectContain({
				kind = TokenKind.NAME,
				start = 9,
				_end = 12,
				line = 4,
				column = 3,
				value = "foo",
			})
		end)

		it("can be JSON.stringified, util.inspected or jsutils.inspect", function()
			local token = lexOne("foo")
			-- ROBLOX deviation: no JSON.stringify and node inspect in Lua

			expect(token).toObjectContain({
				kind = "Name",
				line = 1,
				column = 1,
				value = "foo",
			})
			-- ROBLOX deviation: key order is different
			expect(inspect(token)).toEqual("{ value: \"foo\", kind: \"Name\", column: 1, line: 1 }")
		end)

		it("skips whitespace and comments", function()
			expect(lexOne("\n\n    foo\n\n\n")).toObjectContain({
				kind = TokenKind.NAME,
				start = 7,
				_end = 10,
				value = "foo",
			})

			expect(lexOne("\n    #connent\n    foo#comment\n")).toObjectContain({
				kind = TokenKind.NAME,
				start = 19,
				_end = 22,
				value = "foo",
			})

			expect(lexOne(",,,foo,,,")).toObjectContain({
				kind = TokenKind.NAME,
				start = 4,
				_end = 7,
				value = "foo",
			})
		end)

		it("errors respect whitespace", function()
			local caughtError
			xpcall(function()
				lexOne(Array.join({ "", "", "    ?", "" }, "\n"))
			end, function(e)
				caughtError = e
			end)
			expect(tostring(caughtError) .. "\n").to.equal(dedent([[
			  Syntax Error: Cannot parse the unexpected character "?".

			  GraphQL request:3:5
			  2 |
			  3 |     ?
			    |     ^
			  4 |
			]]))
		end)

		it("updates line numbers in error for file context", function()
			local caughtError
			xpcall(function()
				local str = Array.join({ "", "", "     ?", "" }, "\n")
				local source = Source.new(str, "foo.js", { line = 11, column = 12 })
				Lexer.new(source):advance()
			end, function(e)
				caughtError = e
			end)
			expect(tostring(caughtError) .. "\n").to.equal(dedent([[
			  Syntax Error: Cannot parse the unexpected character "?".

			  foo.js:13:6
			  12 |
			  13 |      ?
			     |      ^
			  14 |
			]]))
		end)

		it("updates column numbers in error for file context", function()
			local caughtError
			xpcall(function()
				local source = Source.new("?", "foo.js", { line = 1, column = 5 })
				Lexer.new(source):advance()
			end, function(e)
				caughtError = e
			end)
			expect(tostring(caughtError) .. "\n").to.equal(dedent([[
			  Syntax Error: Cannot parse the unexpected character "?".

			  foo.js:1:5
			  1 |     ?
			    |     ^
			]]))
		end)

		it("lexes strings", function()
			expect(lexOne("\"\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 3,
				value = "",
			})

			expect(lexOne("\"simple\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 9,
				value = "simple",
			})

			expect(lexOne("\" white space \"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 16,
				value = " white space ",
			})

			expect(lexOne("\"quote \\\"\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 11,
				value = "quote \"",
			})

			expect(lexOne("\"escaped \\n\\r\\b\\t\\f\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 21,
				value = "escaped \n\r\b\t\f",
			})

			expect(lexOne("\"slashes \\\\ \\/\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 16,
				value = "slashes \\ /",
			})

			expect(lexOne("\"unicode \\u1234\\u5678\\u90AB\\uCDEF\"")).toObjectContain({
				kind = TokenKind.STRING,
				start = 1,
				_end = 35,
				value = "unicode \u{1234}\u{5678}\u{90AB}\u{CDEF}",
			})
		end)

		itSKIP("lex reports useful string errors", function()
			-- ROBLOX TODO: isn't throwing errors like it should
			expectSyntaxError("\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 2 } },
			})

			expectSyntaxError("\"\"\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 4 } },
			})

			expectSyntaxError("\"\"\"\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 5 } },
			})

			expectSyntaxError("\"no end quote").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 14 } },
			})

			expectSyntaxError("'single quotes'").toEqual({
				message = "Syntax Error: Unexpected single quote character ('), did you mean to use a double quote (\")?",
				locations = { { line = 1, column = 1 } },
			})

			expectSyntaxError("\"contains unescaped \\u0007 control char\"").toEqual({
				message = "Syntax Error: Invalid character within String: \"\\u0007\".",
				locations = { { line = 1, column = 21 } },
			})

			expectSyntaxError("\"null-byte is not \\u0000 end of file\"").toEqual({
				message = "Syntax Error: Invalid character within String: \"\\u0000\".",
				locations = { { line = 1, column = 19 } },
			})

			expectSyntaxError("\"multi\nline\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"multi\rline\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\z esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\z.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\x esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\x.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\u1 esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\u1 es.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\u0XX1 esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\u0XX1.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\uXXXX esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\uXXXX.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\uFXXX esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\uFXXX.",
				locations = { { line = 1, column = 7 } },
			})

			expectSyntaxError("\"bad \\uXXXF esc\"").toEqual({
				message = "Syntax Error: Invalid character escape sequence: \\uXXXF.",
				locations = { { line = 1, column = 7 } },
			})
		end)

		itSKIP("lexes block strings", function()
			expect(lexOne("\"\"\"\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 6,
				value = "",
			})

			expect(lexOne("\"\"\" white space \"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 19,
				value = " white space ",
			})

			expect(lexOne("\"\"\"contains \" quote\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 22,
				value = "contains \" quote",
			})

			expect(lexOne("\"\"\"contains \\\"\"\" triple quote\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 32,
				value = "contains \"\"\" triple quote",
			})

			expect(lexOne("\"\"\"multi\nline\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 16,
				value = "multi\nline",
			})

			expect(lexOne("\"\"\"multi\rline\r\nnormalized\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 28,
				value = "multi\nline\nnormalized",
			})

			expect(lexOne("\"\"\"unescaped \\n\\r\\b\\t\\f\\u1234\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 32,
				value = "unescaped \\n\\r\\b\\t\\f\\u1234",
			})

			expect(lexOne("\"\"\"slashes \\\\ \\/\"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 19,
				value = "slashes \\\\ \\/",
			})

			expect(lexOne("\"\"\"\n\n        spans\n          multiple\n            lines\n\n        \"\"\"")).toObjectContain({
				kind = TokenKind.BLOCK_STRING,
				start = 0,
				_end = 68,
				value = "spans\n  multiple\n    lines",
			})
		end)

		itSKIP("advance line after lexing multiple block string", function()
			-- expect(
			-- 	lexSecond('"""\n\n        spans\n          multiple\n            lines\n\n        \n """ second_token')
			-- ).toObjectContain({
			-- 	kind = TokenKind.NAME,
			-- 	start = 71,
			-- 	_end = 83,
			-- 	line = 8,
			-- 	column = 6,
			-- 	value = 'second_token'
			-- })
			local actual = lexSecond("\"\"\"\n\n        spans\n          multiple\n            lines\n\n        \n \"\"\" second_token")
			-- ROBLOX TODO: lexSecond() incorrectly returns nil for the above string
			expect(actual.kind).toEqual(TokenKind.NAME)
			expect(actual.start).toEqual(71)
			expect(actual._end).toEqual(83)
			expect(actual.line).toEqual(8)
			expect(actual.column).toEqual(6)
			expect(actual.value).toEqual("second_token")
		end)

		itSKIP("lex reports useful block string errors", function()
			-- ROBLOX TODO: not currently throwing errors like it should
			expectSyntaxError("\"\"\"").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 4 } },
			})

			expectSyntaxError("\"\"\"no end quote").toEqual({
				message = "Syntax Error: Unterminated string.",
				locations = { { line = 1, column = 16 } },
			})

			expectSyntaxError("\"\"\"contains unescaped \\u0007 control char\"\"\"").toEqual({
				message = "Syntax Error: Invalid character within String: \"\\u0007\".",
				locations = { { line = 1, column = 23 } },
			})

			expectSyntaxError("\"\"\"null-byte is not \\u0000 end of file\"\"\"").toEqual({
				message = "Syntax Error: Invalid character within String: \"\\u0000\".",
				locations = { { line = 1, column = 21 } },
			})
		end)

		-- ROBLOX deviation: no "contains" matcher, so match fields individually
		itSKIP("lexes numbers", function()
			-- expect(lexOne('4')).toObjectContain({
			-- 	kind = TokenKind.INT,
			-- 	start = 0,
			-- 	_end = 1,
			-- 	value = '4'
			-- })
			local actual = lexOne("4")
			expect(actual.kind).toEqual(TokenKind.INT)
			expect(actual.start).toEqual(0)
			expect(actual._end).toEqual(1)
			expect(actual.value).toEqual("4")

			-- expect(lexOne('4.123')).toObjectContain({
			-- 	kind = TokenKind.FLOAT,
			-- 	start = 0,
			-- 	_end = 5,
			-- 	value = '4.123'
			-- })
			actual = lexOne("4.123")
			expect(actual.kind).toEqual(TokenKind.FLOAT)
			expect(actual.start).toEqual(0)
			expect(actual._end).toEqual(5)
			-- ROBLOX TODO: this expect fails due to a bug in the slice() implementation
			-- expect(actual.value).toEqual('4.123')

			--   expect(lexOne('-4')).toObjectContain({
			--     kind = TokenKind.INT,
			--     start = 0,
			--     _end = 2,
			--     value = '-4',
			--   })

			--   expect(lexOne('9')).toObjectContain({
			--     kind = TokenKind.INT,
			--     start = 0,
			--     _end = 1,
			--     value = '9',
			--   })

			--   expect(lexOne('0')).toObjectContain({
			--     kind = TokenKind.INT,
			--     start = 0,
			--     _end = 1,
			--     value = '0',
			--   })

			--   expect(lexOne('-4.123')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 6,
			--     value = '-4.123',
			--   })

			--   expect(lexOne('0.123')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 5,
			--     value = '0.123',
			--   })

			--   expect(lexOne('123e4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 5,
			--     value = '123e4',
			--   })

			--   expect(lexOne('123E4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 5,
			--     value = '123E4',
			--   })

			--   expect(lexOne('123e-4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 6,
			--     value = '123e-4',
			--   })

			--   expect(lexOne('123e+4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 6,
			--     value = '123e+4',
			--   })

			--   expect(lexOne('-1.123e4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 8,
			--     value = '-1.123e4',
			--   })

			--   expect(lexOne('-1.123E4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 8,
			--     value = '-1.123E4',
			--   })

			--   expect(lexOne('-1.123e-4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 9,
			--     value = '-1.123e-4',
			--   })

			--   expect(lexOne('-1.123e+4')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 9,
			--     value = '-1.123e+4',
			--   })

			--   expect(lexOne('-1.123e4567')).toObjectContain({
			--     kind = TokenKind.FLOAT,
			--     start = 0,
			--     _end = 11,
			--     value = '-1.123e4567',
			--   })
			-- })

			-- it('lex reports useful number errors', function()
			--   expectSyntaxError('00').toEqual({
			--     message = 'Syntax Error: Invalid number, unexpected digit after 0: "0".',
			--     locations = {{ line = 1, column = 2 }}
			--   })

			--   expectSyntaxError('01').toEqual({
			--     message = 'Syntax Error: Invalid number, unexpected digit after 0: "1".',
			--     locations = {{ line = 1, column = 2 }}
			--   })

			--   expectSyntaxError('01.23').toEqual({
			--     message = 'Syntax Error: Invalid number, unexpected digit after 0: "1".',
			--     locations = {{ line = 1, column = 2 }}
			--   })

			--   expectSyntaxError('+1').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "+".',
			--     locations = {{ line = 1, column = 1 }}
			--   })

			--   expectSyntaxError('1.').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: <EOF>.',
			--     locations = {{ line = 1, column = 3 }}
			--   })

			--   expectSyntaxError('1e').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: <EOF>.',
			--     locations = {{ line = 1, column = 3 }}
			--   })

			--   expectSyntaxError('1E').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: <EOF>.',
			--     locations = {{ line = 1, column = 3 }}
			--   })

			--   expectSyntaxError('1.e1').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "e".',
			--     locations = {{ line = 1, column = 3 }}
			--   })

			--   expectSyntaxError('.123').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character ".".',
			--     locations = {{ line = 1, column = 1 }}
			--   })

			--   expectSyntaxError('1.A').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "A".',
			--     locations = {{ line = 1, column = 3 }}
			--   })

			--   expectSyntaxError('-A').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "A".',
			--     locations = {{ line = 1, column = 2 }}
			--   })

			--   expectSyntaxError('1.0e').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: <EOF>.',
			--     locations = {{ line = 1, column = 5 }}
			--   })

			--   expectSyntaxError('1.0eA').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "A".',
			--     locations = {{ line = 1, column = 5 }}
			--   })

			--   expectSyntaxError('1.2e3e').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "e".',
			--     locations = {{ line = 1, column = 6 }}
			--   })

			--   expectSyntaxError('1.2e3.4').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: ".".',
			--     locations = {{ line = 1, column = 6 }}
			--   })

			--   expectSyntaxError('1.23.4').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: ".".',
			--     locations = {{ line = 1, column = 5 }}
			--   })
			-- })

			-- it('lex does not allow name-start after a number', function()
			--   expectSyntaxError('0xF1').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "x".',
			--     locations = {{ line = 1, column = 2 }}
			--   })
			--   expectSyntaxError('0b10').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "b".',
			--     locations = {{ line = 1, column = 2 }}
			--   })
			--   expectSyntaxError('123abc').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "a".',
			--     locations = {{ line = 1, column = 4 }}
			--   })
			--   expectSyntaxError('1_234').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "_".',
			--     locations = {{ line = 1, column = 2 }}
			--   })
			--   expectSyntaxError('1ß').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "\\u00DF".',
			--     locations = {{ line = 1, column = 2 }}
			--   })
			--   expectSyntaxError('1.23f').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "f".',
			--     locations = {{ line = 1, column = 5 }}
			--   })
			--   expectSyntaxError('1.234_5').toEqual({
			--     message = 'Syntax Error: Invalid number, expected digit but got: "_".',
			--     locations = {{ line = 1, column = 6 }}
			--   })
			--   expectSyntaxError('1ß').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "\\u00DF".',
			--     locations = {{ line = 1, column = 2 }}
			--   })
			-- })

			-- it('lexes punctuation', function()
			--   expect(lexOne('!')).toObjectContain({
			--     kind = TokenKind.BANG,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('$')).toObjectContain({
			--     kind = TokenKind.DOLLAR,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('(')).toObjectContain({
			--     kind = TokenKind.PAREN_L,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne(')')).toObjectContain({
			--     kind = TokenKind.PAREN_R,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('...')).toObjectContain({
			--     kind = TokenKind.SPREAD,
			--     start = 0,
			--     _end = 3,
			--     value = undefined,
			--   })

			--   expect(lexOne(':')).toObjectContain({
			--     kind = TokenKind.COLON,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('=')).toObjectContain({
			--     kind = TokenKind.EQUALS,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('@')).toObjectContain({
			--     kind = TokenKind.AT,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('[')).toObjectContain({
			--     kind = TokenKind.BRACKET_L,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne(']')).toObjectContain({
			--     kind = TokenKind.BRACKET_R,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('{')).toObjectContain({
			--     kind = TokenKind.BRACE_L,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('|')).toObjectContain({
			--     kind = TokenKind.PIPE,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })

			--   expect(lexOne('}')).toObjectContain({
			--     kind = TokenKind.BRACE_R,
			--     start = 0,
			--     _end = 1,
			--     value = undefined,
			--   })
			-- })

			-- it('lex reports useful unknown character error', function()
			--   expectSyntaxError('..').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character ".".',
			--     locations = {{ line = 1, column = 1 }}
			--   })

			--   expectSyntaxError('?').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "?".',
			--     locations = {{ line = 1, column = 1 }}
			--   })

			--   expectSyntaxError('\u203B').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "\\u203B".',
			--     locations = {{ line = 1, column = 1 }}
			--   })

			--   expectSyntaxError('\u200b').toEqual({
			--     message = 'Syntax Error: Cannot parse the unexpected character "\\u200B".',
			--     locations = {{ line = 1, column = 1 }}
			--   })
			-- })

			-- it('lex reports useful information for dashes in names', function()
			--   const source = new Source('a-b')
			--   const lexer = new Lexer(source)
			--   const firstToken = lexer.advance()
			--   expect(firstToken).toObjectContain({
			--     kind = TokenKind.NAME,
			--     start = 0,
			--     _end = 1,
			--     value = 'a',
			--   })

			--   expect(() => lexer.advance())
			--     .throw(GraphQLError)
			--     .that.deep.include({
			--       message = 'Syntax Error: Invalid number, expected digit but got: "b".',
			--       locations = {{ line = 1, column = 3 }}
			--     })
			-- })

			-- it('produces double linked list of tokens, including comments', function()
			--   const source = new Source(`
			--     {
			--       #comment
			--       field
			--     }
			--   `)

			--   const lexer = new Lexer(source)
			--   const startToken = lexer.token
			--   let endToken
			--   do {
			--     endToken = lexer.advance()
			--     // Lexer advances over ignored comment tokens to make writing parsers
			--     // easier, but will include them in the linked list result.
			--     expect(endToken.kind).to.not.equal(TokenKind.COMMENT)
			--   } while (endToken.kind !== TokenKind.EOF)

			--   expect(startToken.prev).to.equal(null)
			--   expect(endToken.next).to.equal(null)

			--   const tokens = []
			--   for (let tok = startToken tok tok = tok.next) {
			--     if (tokens.length) {
			--       // Tokens are double-linked, prev should point to last seen token.
			--       expect(tok.prev).to.equal(tokens[tokens.length - 1])
			--     }
			--     tokens.push(tok)
			--   }

			--   expect(tokens.map((tok) => tok.kind)).toEqual([
			--     TokenKind.SOF,
			--     TokenKind.BRACE_L,
			--     TokenKind.COMMENT,
			--     TokenKind.NAME,
			--     TokenKind.BRACE_R,
			--     TokenKind.EOF,
			--   ])
			-- })
		end)
	end)
end
