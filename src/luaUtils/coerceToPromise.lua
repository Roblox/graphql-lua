local srcWorkspace = script.Parent.Parent
local Promise = require(srcWorkspace.Parent.Promise)
local PromiseOrValueModule = require(srcWorkspace.jsutils.PromiseOrValue)
type PromiseOrValue<T> = PromiseOrValueModule.PromiseOrValue<T>
local PromiseModule = require(srcWorkspace.luaUtils.Promise)
type Promise<T> = PromiseModule.Promise<T>

local function coerceToPromise(value: PromiseOrValue<any>) : Promise<any>
	if Promise.is(value) then
		return value
	else
		return Promise.resolve(value)
	end
end

return {
	coerceToPromise = coerceToPromise
}
