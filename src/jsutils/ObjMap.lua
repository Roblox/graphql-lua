-- upstream: https://github.com/graphql/graphql-js/blob/7b3241329e1ff49fb647b043b80568f0cf9e1a7c/src/jsutils/ObjMap.js

export type ObjMap<T> = { [string]: T }
export type ObjMapLike<T> = ObjMap<T> | { [string]: T };

export type ReadOnlyObjMap<T> = { [string]: T }
export type ReadOnlyObjMapLike<T> = ReadOnlyObjMap<T>
	| { [string]: T };

return {}
