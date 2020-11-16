local HttpService = game:GetService("HttpService")

local jsutils = script.Parent
local nodejsCustomInspectSymbol = require(jsutils.nodejsCustomInspectSymbol)

local Array = nil
local Object = nil

local MAX_ARRAY_LENGTH = 10
local MAX_RECURSIVE_DEPTH = 2

-- deviation: pre-declare function
local formatValue
local formatObjectValue
local formatArray
local formatObject
local getCustomFn
local getObjectTag

--[[
 * Used to print values in error messages.
 ]]
local function inspect(value)
	return formatValue(value, {})
end

function formatValue(value, seenValues)
	local valueType = typeof(value)
	if valueType == "string" then
		return HttpService:JSONEncode(value)
	elseif valueType == "function" then
		-- deviation: functions don't have names in Lua
		return "[function]"
	elseif valueType == "table" then
		return formatObjectValue(value, seenValues)
	else
		return tostring(value)
	end
end

function formatObjectValue(value, previouslySeenValues)
	if table.find(previouslySeenValues, value) ~= nil then
		return "[Circular]"
	end

	local seenValues = unpack(previouslySeenValues)
	table.insert(seenValues, value)
	local customInspectFn = getCustomFn(value)

	if customInspectFn ~= nil then
		local customValue = customInspectFn(value)

		if customValue ~= value then
			if typeof(customValue) == "string" then
				return customValue
			else
				return formatValue(customValue, seenValues)
			end
		end
	elseif Array.isArray(value) then
		return formatArray(value, seenValues)
	end

	return formatObject(value, seenValues)
end

function formatObject(object, seenValues)
	local keys = Object.keys(object)

	if keys.length == 0 then
		return "{}"
	end
	if seenValues.length > MAX_RECURSIVE_DEPTH then
		return "[" .. getObjectTag(object) .. "]"
	end

	local properties = keys.map(function(key)
		local value = formatValue(object[key], seenValues)

		return key .. ": " .. value
	end)

	return "{ " .. table.concat(properties, ", ") .. " }"
end

function formatArray(array, seenValues)
	local length = #array
	if length == 0 then
		return "[]"
	end
	if length > MAX_RECURSIVE_DEPTH then
		return "[Array]"
	end

	local len = math.min(MAX_ARRAY_LENGTH, length)
	local remaining = length - len
	local items = {}

	for i = 1, len do
		items[i] = (formatValue(array[i], seenValues))
	end

	if remaining == 1 then
		table.insert(items, "... 1 more item")
	elseif remaining > 1 then
		table.insert(items, ("... %s more items"):format(remaining))
	end

	return "[" .. items.join(", ") .. "]"
end

function getCustomFn(object)
	local customInspectFn = object[nodejsCustomInspectSymbol]

	if typeof(customInspectFn) == "function" then
		return customInspectFn
	end
	if typeof(object.inspect) == "function" then
		return object.inspect
	end
	return nil
end

function getObjectTag(object)
	local tag = Object.prototype.toString
		.call(object)
		.replace("")
		.replace("")

	if tag == "Object" and typeof(object.constructor) == "function" then
		local name = object.constructor.name

		if typeof(name) == "string" and name ~= "" then
			return name
		end
	end

	return tag
end

return inspect
