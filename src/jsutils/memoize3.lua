-- upstream: https://github.com/graphql/graphql-js/blob/bbd8429b85594d9ee8cc632436e2d0f900d703ef/src/jsutils/memoize3.js
-- deviation: we need to replace 'nil' with a symbol
-- in the table to support it
local NULL = {}

local function replaceNil(value)
	if value == nil then
		return NULL
	end
	return value
end

local function newWeakMap()
	return setmetatable({}, { __mode = "kv" })
end

--[[
 * Memoizes the provided three-argument function.
 ]]
return function(fn)
    local cache0

	return function(a1, a2, a3)
		-- deviation: we replace 'nil' with a table to support
		-- caching with null values
		local key1 = replaceNil(a1)
		local key2 = replaceNil(a2)
		local key3 = replaceNil(a3)

		if not cache0 then
			cache0 = newWeakMap
        end
        local cache1 = cache0[key1]
        local cache2

        if cache1 then
            cache2 = cache1[key2]

            if cache2 then
                local cachedValue = cache2[key3]

				if cachedValue ~= nil then
					-- deviation: since we store nil as NULL
					-- we need to check for it
					if cachedValue == NULL then
						return nil
					end
                    return cachedValue
                end
            end
        else
            cache0[key1] = cache1
        end
        if not cache2 then
            cache1[key2] = cache2
        end

        local newValue = fn(a1, a2, a3)

		cache2[key3] = replaceNil(newValue)

        return newValue
    end
end
