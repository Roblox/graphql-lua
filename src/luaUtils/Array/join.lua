type Array<T> = { [number]: T }

return function(arr: Array<string>, separator: string?)
	return table.concat(arr, separator or ",")
end
