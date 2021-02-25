-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/findBreakingChanges.js

local srcWorkspace = script.Parent.Parent
local rootWorkspace = srcWorkspace.Parent

local LuauPolyfill = require(rootWorkspace.Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local UtilArray = require(srcWorkspace.luaUtils.Array)
local keyMapOrdered = require(srcWorkspace.luaUtils.keyMapOrdered).keyMapOrdered

local jsutils = srcWorkspace.jsutils
local inspect = require(jsutils.inspect).inspect
local invariant = require(jsutils.invariant).invariant
local naturalCompare = require(jsutils.naturalCompare).naturalCompare

local language = srcWorkspace.language
local print_ = require(language.printer).print
local visit = require(language.visitor).visit

local typeDir = srcWorkspace.type
local isSpecifiedScalarType = require(typeDir.scalars).isSpecifiedScalarType
local definition = require(typeDir.definition)
local isScalarType = definition.isScalarType
local isObjectType = definition.isObjectType
local isInterfaceType = definition.isInterfaceType
local isUnionType = definition.isUnionType
local isEnumType = definition.isEnumType
local isInputObjectType = definition.isInputObjectType
local isNonNullType = definition.isNonNullType
local isListType = definition.isListType
local isNamedType = definition.isNamedType
local isRequiredArgument = definition.isRequiredArgument
local isRequiredInputField = definition.isRequiredInputField

local astFromValue = require(script.Parent.astFromValue).astFromValue

local findSchemaChanges
local findTypeChanges
local findDirectiveChanges
local diff
local findEnumTypeChanges
local findUnionTypeChanges
local findInputObjectTypeChanges
local findFieldChanges
local findImplementedInterfacesChanges
local typeKindName
local isChangeSafeForInputObjectFieldOrFieldArg
local findArgChanges
local isChangeSafeForObjectOrInterfaceField
local stringifyValue

local BreakingChangeType = Object.freeze({
	TYPE_REMOVED = "TYPE_REMOVED",
	TYPE_CHANGED_KIND = "TYPE_CHANGED_KIND",
	TYPE_REMOVED_FROM_UNION = "TYPE_REMOVED_FROM_UNION",
	VALUE_REMOVED_FROM_ENUM = "VALUE_REMOVED_FROM_ENUM",
	REQUIRED_INPUT_FIELD_ADDED = "REQUIRED_INPUT_FIELD_ADDED",
	IMPLEMENTED_INTERFACE_REMOVED = "IMPLEMENTED_INTERFACE_REMOVED",
	FIELD_REMOVED = "FIELD_REMOVED",
	FIELD_CHANGED_KIND = "FIELD_CHANGED_KIND",
	REQUIRED_ARG_ADDED = "REQUIRED_ARG_ADDED",
	ARG_REMOVED = "ARG_REMOVED",
	ARG_CHANGED_KIND = "ARG_CHANGED_KIND",
	DIRECTIVE_REMOVED = "DIRECTIVE_REMOVED",
	DIRECTIVE_ARG_REMOVED = "DIRECTIVE_ARG_REMOVED",
	REQUIRED_DIRECTIVE_ARG_ADDED = "REQUIRED_DIRECTIVE_ARG_ADDED",
	DIRECTIVE_REPEATABLE_REMOVED = "DIRECTIVE_REPEATABLE_REMOVED",
	DIRECTIVE_LOCATION_REMOVED = "DIRECTIVE_LOCATION_REMOVED",
})

local DangerousChangeType = Object.freeze({
	VALUE_ADDED_TO_ENUM = "VALUE_ADDED_TO_ENUM",
	TYPE_ADDED_TO_UNION = "TYPE_ADDED_TO_UNION",
	OPTIONAL_INPUT_FIELD_ADDED = "OPTIONAL_INPUT_FIELD_ADDED",
	OPTIONAL_ARG_ADDED = "OPTIONAL_ARG_ADDED",
	IMPLEMENTED_INTERFACE_ADDED = "IMPLEMENTED_INTERFACE_ADDED",
	ARG_DEFAULT_VALUE_CHANGE = "ARG_DEFAULT_VALUE_CHANGE",
})

--[[*
--  * Given two schemas, returns an Array containing descriptions of all the types
--  * of breaking changes covered by the other functions down below.
--  *]]
local function findBreakingChanges(oldSchema, newSchema)
	local breakingChanges = Array.filter(findSchemaChanges(oldSchema, newSchema), function(change)
		return BreakingChangeType[change.type] ~= nil
	end)
	return breakingChanges
end

--[[*
--  * Given two schemas, returns an Array containing descriptions of all the types
--  * of potentially dangerous changes covered by the other functions down below.
--  *]]
local function findDangerousChanges(oldSchema, newSchema)
	local dangerousChanges = Array.filter(findSchemaChanges(oldSchema, newSchema), function(change)
		return DangerousChangeType[change.type] ~= nil
	end)
	return dangerousChanges
end

function findSchemaChanges(oldSchema, newSchema)
	return UtilArray.concat(
		findTypeChanges(oldSchema, newSchema),
		findDirectiveChanges(oldSchema, newSchema)
	)
end

function findDirectiveChanges(oldSchema, newSchema)
	local schemaChanges = {}

	local directivesDiff = diff(oldSchema:getDirectives(), newSchema:getDirectives())

	for _, oldDirective in ipairs(directivesDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.DIRECTIVE_REMOVED,
			description = ("%s was removed."):format(oldDirective.name),
		})
	end

	for _, directive in ipairs(directivesDiff.persisted) do
		local oldDirective = directive[1]
		local newDirective = directive[2]
		local argsDiff = diff(oldDirective.args, newDirective.args)

		for _, newArg in ipairs(argsDiff.added) do
			if isRequiredArgument(newArg) then
				table.insert(schemaChanges, {
					type = BreakingChangeType.REQUIRED_DIRECTIVE_ARG_ADDED,
					description = ("A required arg %s on directive %s was added."):format(newArg.name, oldDirective.name),
				})
			end
		end

		for _, oldArg in ipairs(argsDiff.removed) do
			table.insert(schemaChanges, {
				type = BreakingChangeType.DIRECTIVE_ARG_REMOVED,
				description = ("%s was removed from %s."):format(oldArg.name, oldDirective.name),
			})
		end

		if oldDirective.isRepeatable and not newDirective.isRepeatable then
			table.insert(schemaChanges, {
				type = BreakingChangeType.DIRECTIVE_REPEATABLE_REMOVED,
				description = ("Repeatable flag was removed from %s."):format(oldDirective.name),
			})
		end

		for _, location in ipairs(oldDirective.locations) do
			if table.find(newDirective.locations, location) == nil then
				table.insert(schemaChanges, {
					type = BreakingChangeType.DIRECTIVE_LOCATION_REMOVED,
					description = ("%s was removed from %s."):format(location, oldDirective.name),
				})
			end
		end
	end

	return schemaChanges
end

function findTypeChanges(oldSchema, newSchema)
	local schemaChanges = {}

	local typesDiff = diff(oldSchema:getTypeMap():values(), newSchema:getTypeMap():values())

	for _, oldType in ipairs(typesDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.TYPE_REMOVED,
			description = isSpecifiedScalarType(oldType) and ("Standard scalar %s was removed because it is not referenced anymore."):format(oldType.name) or ("%s was removed."):format(oldType.name),
		})
	end

	for _, type_ in ipairs(typesDiff.persisted) do
		local oldType = type_[1]
		local newType = type_[2]
		if isEnumType(oldType) and isEnumType(newType) then
			for _, item in ipairs(findEnumTypeChanges(oldType, newType)) do
				table.insert(schemaChanges, item)
			end
		elseif isUnionType(oldType) and isUnionType(newType) then
			for _, item in ipairs(findUnionTypeChanges(oldType, newType)) do
				table.insert(schemaChanges, item)
			end
		elseif isInputObjectType(oldType) and isInputObjectType(newType) then
			for _, item in ipairs(findInputObjectTypeChanges(oldType, newType)) do
				table.insert(schemaChanges, item)
			end
		elseif isObjectType(oldType) and isObjectType(newType) then
			for _, item in ipairs(UtilArray.concat(
				findFieldChanges(oldType, newType),
				findImplementedInterfacesChanges(oldType, newType)
			)) do
				table.insert(schemaChanges, item)
			end
		elseif isInterfaceType(oldType) and isInterfaceType(newType) then
			-- selene: allow(if_same_then_else)
			for _, item in ipairs(UtilArray.concat(
				findFieldChanges(oldType, newType),
				findImplementedInterfacesChanges(oldType, newType)
			)) do
				table.insert(schemaChanges, item)
			end
		elseif oldType.new ~= newType.new then
			table.insert(schemaChanges, {
				type = BreakingChangeType.TYPE_CHANGED_KIND,
				description = ("%s changed from %s to %s."):format(oldType.name, typeKindName(oldType), typeKindName(newType)),
			})
		end
	end
	return schemaChanges
end

function findInputObjectTypeChanges(oldType, newType)
	local schemaChanges = {}
	-- ROBLOX deviation: use Map
	local fieldsDiff = diff(oldType:getFields():values(), newType:getFields():values())

	for _, newField in ipairs(fieldsDiff.added) do
		if isRequiredInputField(newField) then
			table.insert(schemaChanges, {
				type = BreakingChangeType.REQUIRED_INPUT_FIELD_ADDED,
				description = ("A required field %s on input type %s was added."):format(newField.name, oldType.name),
			})
		else
			table.insert(schemaChanges, {
				type = DangerousChangeType.OPTIONAL_INPUT_FIELD_ADDED,
				description = ("An optional field %s on input type %s was added."):format(newField.name, oldType.name),
			})
		end
	end

	for _, oldField in ipairs(fieldsDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.FIELD_REMOVED,
			description = ("%s.%s was removed."):format(oldType.name, oldField.name),
		})
	end

	for _, field in ipairs(fieldsDiff.persisted) do
		local oldField = field[1]
		local newField = field[2]
		local isSafe = isChangeSafeForInputObjectFieldOrFieldArg(oldField.type, newField.type)
		if not isSafe then
			table.insert(schemaChanges, {
				type = BreakingChangeType.FIELD_CHANGED_KIND,
				description = ("%s.%s changed type from %s to %s."):format(oldType.name, oldField.name, tostring(oldField.type), tostring(newField.type)),
			})
		end
	end

	return schemaChanges
end

function findUnionTypeChanges(oldType, newType)
	local schemaChanges = {}
	local possibleTypesDiff = diff(oldType:getTypes(), newType:getTypes())

	for _, newPossibleType in ipairs(possibleTypesDiff.added) do
		table.insert(schemaChanges, {
			type = DangerousChangeType.TYPE_ADDED_TO_UNION,
			description = ("%s was added to union type %s."):format(newPossibleType.name, oldType.name),
		})
	end
	for _, oldPossibleType in ipairs(possibleTypesDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.TYPE_REMOVED_FROM_UNION,
			description = ("%s was removed from union type %s."):format(oldPossibleType.name, oldType.name),
		})
	end

	return schemaChanges
end

function findEnumTypeChanges(oldType, newType)
	local schemaChanges = {}
	local valuesDiff = diff(oldType:getValues(), newType:getValues())

	for _, newValue in ipairs(valuesDiff.added) do
		table.insert(schemaChanges, {
			type = DangerousChangeType.VALUE_ADDED_TO_ENUM,
			description = ("%s was added to enum type %s."):format(newValue.name, oldType.name),
		})
	end
	for _, oldValue in ipairs(valuesDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.VALUE_REMOVED_FROM_ENUM,
			description = ("%s was removed from enum type %s."):format(oldValue.name, oldType.name),
		})
	end

	return schemaChanges
end
function findImplementedInterfacesChanges(oldType, newType)
	local schemaChanges = {}
	local interfacesDiff = diff(oldType:getInterfaces(), newType:getInterfaces())

	for _, newInterface in ipairs(interfacesDiff.added) do
		table.insert(schemaChanges, {
			type = DangerousChangeType.IMPLEMENTED_INTERFACE_ADDED,
			description = ("%s added to interfaces implemented by %s."):format(newInterface.name, oldType.name),
		})
	end
	for _, oldInterface in ipairs(interfacesDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.IMPLEMENTED_INTERFACE_REMOVED,
			description = ("%s no longer implements interface %s."):format(oldType.name, oldInterface.name),
		})
	end

	return schemaChanges
end

function findFieldChanges(oldType, newType)
	local schemaChanges = {}
	-- ROBLOX deviation: use Map
	local fieldsDiff = diff(oldType:getFields():values(), newType:getFields():values())

	for _, oldField in ipairs(fieldsDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.FIELD_REMOVED,
			description = ("%s.%s was removed."):format(oldType.name, oldField.name),
		})
	end
	for _, field in ipairs(fieldsDiff.persisted) do
		local oldField = field[1]
		local newField = field[2]

		for _, value in ipairs(findArgChanges(oldType, oldField, newField)) do
			table.insert(schemaChanges, value)
		end

		local isSafe = isChangeSafeForObjectOrInterfaceField(oldField.type, newField.type)

		if not isSafe then
			table.insert(schemaChanges, {
				type = BreakingChangeType.FIELD_CHANGED_KIND,
				description = ("%s.%s changed type from "):format(oldType.name, oldField.name) .. ("%s to %s."):format(tostring(oldField.type), tostring(newField.type)),
			})
		end
	end

	return schemaChanges
end

function findArgChanges(oldType, oldField, newField)
	local schemaChanges = {}
	local argsDiff = diff(oldField.args, newField.args)

	for _, oldArg in ipairs(argsDiff.removed) do
		table.insert(schemaChanges, {
			type = BreakingChangeType.ARG_REMOVED,
			description = ("%s.%s arg %s was removed."):format(oldType.name, oldField.name, oldArg.name),
		})
	end
	for _, arg in ipairs(argsDiff.persisted) do
		local oldArg = arg[1]
		local newArg = arg[2]
		local isSafe = isChangeSafeForInputObjectFieldOrFieldArg(oldArg.type, newArg.type)

		if not isSafe then
			table.insert(schemaChanges, {
				type = BreakingChangeType.ARG_CHANGED_KIND,
				description = ("%s.%s arg %s has changed type from "):format(oldType.name, oldField.name, oldArg.name) .. ("%s to %s."):format(tostring(oldArg.type), tostring(newArg.type)),
			})
		elseif oldArg.defaultValue ~= nil then
			if newArg.defaultValue == nil then
				table.insert(schemaChanges, {
					type = DangerousChangeType.ARG_DEFAULT_VALUE_CHANGE,
					description = ("%s.%s arg %s defaultValue was removed."):format(oldType.name, oldField.name, oldArg.name),
				})
			else
				-- Since we looking only for client's observable changes we should
				-- compare default values in the same representation as they are
				-- represented inside introspection.
				local oldValueStr = stringifyValue(oldArg.defaultValue, oldArg.type)
				local newValueStr = stringifyValue(newArg.defaultValue, newArg.type)

				if oldValueStr ~= newValueStr then
					table.insert(schemaChanges, {
						type = DangerousChangeType.ARG_DEFAULT_VALUE_CHANGE,
						description = ("%s.%s arg %s has changed defaultValue from %s to %s."):format(oldType.name, oldField.name, oldArg.name, oldValueStr, newValueStr),
					})
				end
			end
		end
	end
	for _, newArg in ipairs(argsDiff.added) do
		if isRequiredArgument(newArg) then
			table.insert(schemaChanges, {
				type = BreakingChangeType.REQUIRED_ARG_ADDED,
				description = ("A required arg %s on %s.%s was added."):format(newArg.name, oldType.name, oldField.name),
			})
		else
			table.insert(schemaChanges, {
				type = DangerousChangeType.OPTIONAL_ARG_ADDED,
				description = ("An optional arg %s on %s.%s was added."):format(newArg.name, oldType.name, oldField.name),
			})
		end
	end

	return schemaChanges
end

function isChangeSafeForObjectOrInterfaceField(oldType, newType): boolean
	if isListType(oldType) then
		return isListType(newType)
			and isChangeSafeForObjectOrInterfaceField(oldType.ofType, newType.ofType) -- if they're both lists, make sure the underlying types are compatible
			or isNonNullType(newType)
			and isChangeSafeForObjectOrInterfaceField(oldType, newType.ofType) -- moving from nullable to non-null of the same underlying type is safe
	end
	if isNonNullType(oldType) then
		-- if they're both non-null, make sure the underlying types are compatible
		return isNonNullType(newType) and isChangeSafeForObjectOrInterfaceField(oldType.ofType, newType.ofType)
	end

	return isNamedType(newType)
		and oldType.name == newType.name -- if they're both named types, see if their names are equivalent
		or isNonNullType(newType)
		and isChangeSafeForObjectOrInterfaceField(oldType, newType.ofType) -- moving from nullable to non-null of the same underlying type is safe
end

function isChangeSafeForInputObjectFieldOrFieldArg(oldType, newType): boolean
	if isListType(oldType) then
		-- if they're both lists, make sure the underlying types are compatible
		return isListType(newType) and isChangeSafeForInputObjectFieldOrFieldArg(oldType.ofType, newType.ofType)
	end
	if isNonNullType(oldType) then
		return isNonNullType(newType)
			and isChangeSafeForInputObjectFieldOrFieldArg(oldType.ofType, newType.ofType) -- if they're both non-null, make sure the underlying types are compatible
			or not isNonNullType(newType)
			and isChangeSafeForInputObjectFieldOrFieldArg(oldType.ofType, newType) -- moving from non-null to nullable of the same underlying type is safe
	end

	-- if they're both named types, see if their names are equivalent
	return isNamedType(newType) and oldType.name == newType.name
end

function typeKindName(type_): string
	if isScalarType(type_) then
		return "a Scalar type"
	end
	if isObjectType(type_) then
		return "an Object type"
	end
	if isInterfaceType(type_) then
		return "an Interface type"
	end
	if isUnionType(type_) then
		return "a Union type"
	end
	if isEnumType(type_) then
		return "an Enum type"
	end
	-- istanbul ignore else (See: 'https://github.com/graphql/graphql-js/issues/2618')
	if isInputObjectType(type_) then
		return "an Input type"
	end

	-- istanbul ignore next (Not reachable. All possible named types have been considered)
	invariant(false, "Unexpected type: " .. inspect(type_))

	return "" -- ROBLOX deviation: no implicit return
end

function stringifyValue(value, type_): string
	local ast = astFromValue(value, type_)

	invariant(ast ~= nil)

	local sortedAST = visit(ast, {
		ObjectValue = function(self, objectNode)
			-- Make a copy since sort mutates array
			local fields = Array.concat({}, objectNode.fields)

			Array.sort(fields, function(fieldA, fieldB)
				return naturalCompare(fieldA.name.value, fieldB.name.value)
			end)

			return Object.assign({}, objectNode, { fields = fields })
		end,
	})

	return print_(sortedAST)
end

function diff(oldArray, newArray)
	local added = {}
	local removed = {}
	local persisted = {}
	local oldMap = keyMapOrdered(oldArray, function(arg)
		return arg.name
	end)
	local newMap = keyMapOrdered(newArray, function(arg)
		return arg.name
	end)

	for _, oldItem in ipairs(oldArray) do
		local newItem = newMap:get(oldItem.name)

		if newItem == nil then
			table.insert(removed, oldItem)
		else
			table.insert(persisted, { oldItem, newItem })
		end
	end
	for _, newItem in ipairs(newArray) do
		if oldMap:get(newItem.name) == nil then
			table.insert(added, newItem)
		end
	end

	return {
		added = added,
		persisted = persisted,
		removed = removed,
	}
end

return {
	BreakingChangeType = BreakingChangeType,
	DangerousChangeType = DangerousChangeType,
	findBreakingChanges = findBreakingChanges,
	findDangerousChanges = findDangerousChanges,
}
