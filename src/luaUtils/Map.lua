local LuauPolyfill = script.Parent
local Array = require(LuauPolyfill.Array)

type Array<T> = { [number]: T }
type Tuple<T, V> = Array<T | V>

local Map = {}

export type Map<T, V> = {
	size: number,
	-- method definitions
	set: (T, V) -> Map,
	get: (T) -> V,
	clear: () -> (),
	delete: (T) -> boolean,
	has: (T) -> boolean,
	keys: () -> Array<T>,
	values: () -> Array<V>,
	entries: () -> Array<Tuple<T, V>>,
	ipairs: () -> any,
}

function Map.new(iterable)
	local array = {}
	local map = {}
	if iterable ~= nil then
		local arrayFromIterable
		local iterableType = typeof(iterable)
		if iterableType == "table" then
			arrayFromIterable = Array.from(iterable)
		else
			error(("cannot create array from value of type `%s`"):format(iterableType))
		end

		for _, entry in ipairs(arrayFromIterable) do
			local key = entry[1]
			local val = entry[2]
			if not map[key] then
				map[key] = val
				table.insert(array, key)
			end
		end
	end

	return setmetatable({
		size = #array,
		_map = map,
		_array = array,
	}, Map)
end

function Map:set(key, value)
	-- preserve initial insertion order
	if not self._map[key] then
		self.size += 1
		table.insert(self._array, key)
	end
	-- always update value
	self._map[key] = value
	return self
end

function Map:get(key)
	return self._map[key]
end

function Map:clear()
	local table_: any = table
	self.size = 0
	table_.clear(self._map)
	table_.clear(self._array)
end

function Map:delete(key): boolean
	if not self._map[key] then
		return false
	end
	self.size -= 1
	self._map[key] = nil
	local index = table.find(self._array, key)
	if index then
		table.remove(self._array, index)
	end
	return true
end

function Map:has(key): boolean
	return self._map[key] ~= nil
end

function Map:keys()
	return self._array
end

function Map:values()
	return Array.map(self._array, function(key)
		return self._map[key]
	end)
end

function Map:entries()
	return Array.map(self._array, function(key)
		return { key, self._map[key] }
	end)
end

function Map:ipairs()
	return ipairs(self:entries())
end

function Map.__index(self, key)
	local mapProp = rawget(Map, key)
	if mapProp ~= nil then
		return mapProp
	end

	return Map.get(self, key)
end

function Map.__newindex(table_, key, value)
	table_:set(key, value)
end

return Map
