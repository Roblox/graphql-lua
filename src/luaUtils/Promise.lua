export type PromiseLike<T> = {
    andThen: (
		((T) -> T)? | (PromiseLike<T>)?, -- resolve
		((any) -> () | PromiseLike<T>)? -- reject
	) -> PromiseLike<T>
}

export type Promise<T> = {
    andThen: ((
		((T) -> T | PromiseLike<T>)?, -- resolve
		((any) -> () | PromiseLike<nil>)? -- reject
	) -> Promise<T>)?,

	catch: ((
		((any) -> () | PromiseLike<nil>)
	) -> Promise<T>)?,

	onCancel: ((() -> ()?) -> boolean)?
}

return {}
