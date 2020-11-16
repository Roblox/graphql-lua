return function(condition: any, message: string | nil)
	if not condition then
		error(message or "Unexpected invariant triggered.")
	end
end
