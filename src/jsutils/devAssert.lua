-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/devAssert.js

return function(condition: any, message: string | nil)
	if not condition then
		-- must set error level to zero otherwise msg includes stack
		error(message, 2)
	end
end
