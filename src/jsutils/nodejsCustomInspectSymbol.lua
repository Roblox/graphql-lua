-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/nodejsCustomInspectSymbol.js
local nodejsCustomInspectSymbol = newproxy(true)

getmetatable(nodejsCustomInspectSymbol).__tostring = function()
	return 'nodejs.util.inspect.custom'
end

return nodejsCustomInspectSymbol
