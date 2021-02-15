-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/jsutils/PromiseOrValue.js

-- ROBLOX FIXME: no type info on Promise upstream https://github.com/evaera/roblox-lua-promise/blob/master/lib/init.lua
export type PromiseOrValue<T> = any -- Promise<T> | T;

return {} -- ROBLOX deviation - must return value
