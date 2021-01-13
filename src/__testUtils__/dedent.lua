-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/__testUtils__/dedent.js
--!nolint ImportUnused
--!nolint LocalUnused

return function(strings)
-- 	--...values
-- )
	return strings
	-- local str = ''

	-- for i = 0, #strings, 1 do
	-- 	str = str .. string.sub(strings, i, i)
	-- 	if i < #values then
	-- 		local value = string.sub(values, i, i)

	-- 		str = str .. value -- interpolation
	-- end

	-- for (let i = 0; i < strings.length; ++i) {
  --   str += strings[i];
  --   if (i < values.length) {
  --     // istanbul ignore next (Ignore else inside Babel generated code)
  --     const value = values[i];

  --     str += value; // interpolation
  --   }
	-- }

	-- const trimmedStr = str
  --   .replace(/^\n*/m, '') //  remove leading newline
  --   .replace(/[ \t]*$/, ''); // remove trailing spaces and tabs

  -- // fixes indentation by removing leading spaces and tabs from each line
  -- let indent = '';
  -- for (const char of trimmedStr) {
  --   if (char !== ' ' && char !== '\t') {
  --     break;
  --   }
  --   indent += char;
  -- }
  -- return trimmedStr.replace(RegExp('^' + indent, 'mg'), ''); // remove indent

end
