-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/utilities/getIntrospectionQuery.js

local Object = require(script.Parent.Parent.Parent.Packages.LuauPolyfill).Object
type Array<T> = { [number]: T }
local directiveLocationModule = require(script.Parent.Parent.language.directiveLocation)
type DirectiveLocationEnum = directiveLocationModule.DirectiveLocationEnum

export type IntrospectionOptions = {
  -- Whether to include descriptions in the introspection result.
  -- Default: true
  descriptions: boolean?,

  -- Whether to include `specifiedByUrl` in the introspection result.
  -- Default: false
  specifiedByUrl: boolean?,

  -- Whether to include `isRepeatable` field on directives.
  -- Default: false
  directiveIsRepeatable: boolean?,

  -- Whether to include `description` field on schema.
  -- Default: false
  schemaDescription: boolean?,

  -- Whether target GraphQL server support deprecation of input values.
  -- Default: false
  inputValueDeprecation: boolean?,
}

function getIntrospectionQuery(options: IntrospectionOptions?): string
	local optionsWithDefault = Object.assign(
		{
			descriptions = true,
			specifiedByUrl = false,
			directiveIsRepeatable = false,
			schemaDescription = false,
			inputValueDeprecation = false,
		},
		options
	)

	local descriptions = (function()
		if optionsWithDefault.descriptions then
			return "description"
		else
			return ""
		end
	end)()
	local specifiedByUrl = (function()
		if optionsWithDefault.specifiedByUrl then
			return "specifiedByUrl"
		else
			return ""
		end
	end)()
	local directiveIsRepeatable = (function()
		if optionsWithDefault.directiveIsRepeatable then
			return "isRepeatable"
		else
			return ""
		end
	end)()
	local schemaDescription = (function()
		if optionsWithDefault.schemaDescription then
			return descriptions
		else
			return ""
		end
	end)()

	local function inputDeprecation(str)
		return (function()
			if optionsWithDefault.inputValueDeprecation then
				return str
			else
				return ""
			end
		end)()
	end

	return ([[

    query IntrospectionQuery {
      __schema {
        %s
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types {
          ...FullType
        }
        directives {
          name
          %s
          %s
          locations
          args%s {
            ...InputValue
          }
        }
      }
    }

    fragment FullType on __Type {
      kind
      name
      %s
      %s
      fields(includeDeprecated: true) {
        name
        %s
        args%s {
          ...InputValue
        }
        type {
          ...TypeRef
        }
        isDeprecated
        deprecationReason
      }
      inputFields%s {
        ...InputValue
      }
      interfaces {
        ...TypeRef
      }
      enumValues(includeDeprecated: true) {
        name
        %s
        isDeprecated
        deprecationReason
      }
      possibleTypes {
        ...TypeRef
      }
    }

    fragment InputValue on __InputValue {
      name
      %s
      type { ...TypeRef }
      defaultValue
      %s
      %s
    }

    fragment TypeRef on __Type {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  ]]):format(
		schemaDescription,
		descriptions,
		directiveIsRepeatable,
		inputDeprecation("(includeDeprecated: true)"),
		descriptions,
		specifiedByUrl,
		descriptions,
		inputDeprecation("(includeDeprecated: true)"),
		inputDeprecation("(includeDeprecated: true)"),
		descriptions,
		descriptions,
		inputDeprecation("isDeprecated"),
		inputDeprecation("deprecationReason")
	)
end

export type IntrospectionQuery = {
  __schema: IntrospectionSchema
}

-- ROBLOX FIXME: implement the rest of the types in this file
export type IntrospectionSchema = {
  description: string?,
  queryType: any, -- IntrospectionNamedTypeRef<IntrospectionObjectType>,
  mutationType: any, -- ?IntrospectionNamedTypeRef<IntrospectionObjectType>,
  subscriptionType: any, -- ?IntrospectionNamedTypeRef<IntrospectionObjectType>,
  types: Array<any>, -- <IntrospectionType>,
  directives: Array<any> -- <IntrospectionDirective>,
}

return {
	getIntrospectionQuery = getIntrospectionQuery,
}
