local DEFAULT_NAME = "Error"

local Error = {}
Error.__index = Error

function Error.new(message)
	local self = {
		name = DEFAULT_NAME,
		message = message,
		stack = debug.traceback(),
	}
	return setmetatable(self, Error)
end

function Error:__tostring()
	return string.format("%s: %s", tostring(self.name), tostring(self.message))
end

return Error
