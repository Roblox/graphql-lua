export type ObjMap<T> = { [string]: T }
export type ObjMapLike<T> = ObjMap<T> | { [string]: T };

export type ReadOnlyObjMap<T> = { [string]: T }
export type ReadOnlyObjMapLike<T> = ReadOnlyObjMap<T>
	| { [string]: T };

return {}
