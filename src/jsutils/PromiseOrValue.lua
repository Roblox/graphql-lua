-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/jsutils/PromiseOrValue.js

local PromiseModule = require(script.Parent.Parent.luaUtils.Promise)
type Promise<T> = PromiseModule.Promise<T>

export type PromiseOrValue<T> = Promise<T> | T

return {} -- ROBLOX deviation - must return value
