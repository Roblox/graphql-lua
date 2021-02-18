local srcWorkspace = script.Parent.Parent.Parent
local Array = require(srcWorkspace.Parent.Packages.LuauPolyfill).Array

local function includes(...)
    return Array.indexOf(...) ~= -1
end

return includes