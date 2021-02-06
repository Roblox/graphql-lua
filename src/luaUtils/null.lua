local Object = require(script.Parent.Parent.Parent.Packages.LuauPolyfill).Object

-- ROBLOX deviation: no distinction between undefined and null in Lua so we need to go around this with custom NULL like constant
local NULL = Object.freeze({})

return NULL
