local Object = require(script.Parent.Parent.Parent.Packages.LuauPolyfill).Object

local DirectiveLocation = Object.freeze({
    -- Request Definitions
    QUERY = 'QUERY',
    MUTATION = 'MUTATION',
    SUBSCRIPTION = 'SUBSCRIPTION',
    FIELD = 'FIELD',
    FRAGMENT_DEFINITION = 'FRAGMENT_DEFINITION',
    FRAGMENT_SPREAD = 'FRAGMENT_SPREAD',
    INLINE_FRAGMENT = 'INLINE_FRAGMENT',
    VARIABLE_DEFINITION = 'VARIABLE_DEFINITION',
    -- Type System Definitions
    SCHEMA = 'SCHEMA',
    SCALAR = 'SCALAR',
    OBJECT = 'OBJECT',
    FIELD_DEFINITION = 'FIELD_DEFINITION',
    ARGUMENT_DEFINITION = 'ARGUMENT_DEFINITION',
    INTERFACE = 'INTERFACE',
    UNION = 'UNION',
    ENUM = 'ENUM',
    ENUM_VALUE = 'ENUM_VALUE',
    INPUT_OBJECT = 'INPUT_OBJECT',
    INPUT_FIELD_DEFINITION = 'INPUT_FIELD_DEFINITION',
})

--[[
	ROBLOX FIXME: add types
	Upstream: export type DirectiveLocationEnum = $Values<typeof DirectiveLocation>;
]]
--[[
 * The enum type representing the directive location values.
 *]]
export type DirectiveLocationEnum = any

return {
    DirectiveLocation = DirectiveLocation
}
