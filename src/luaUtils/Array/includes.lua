local srcWorkspace = script.Parent.Parent.Parent
local Array = require(srcWorkspace.Parent.LuauPolyfill).Array

local function includes(...)
    return Array.indexOf(...) ~= -1
end

return includes