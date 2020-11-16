local nodejsCustomInspectSymbol = newproxy(true)

getmetatable(nodejsCustomInspectSymbol).__tostring = function()
	return 'nodejs.util.inspect.custom'
end

return nodejsCustomInspectSymbol
