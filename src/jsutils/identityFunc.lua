-- upstream: https://github.com/graphql/graphql-js/blob/1951bce42092123e844763b6a8e985a8a3327511/src/jsutils/identityFunc.js
--[[
 * Returns the first argument it receives.
 ]]
function identityFunc(x)
	return x
end

return {
	identityFunc = identityFunc,
}
