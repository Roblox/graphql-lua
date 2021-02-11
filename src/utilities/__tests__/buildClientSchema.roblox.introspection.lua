-- introspection mock for "builds a schema without the query type"
-- ROBLOX REMOVEME: remove the file when introspectionFromSchema is implemented

local Array = require(script.Parent.Parent.Parent.luaUtils.Array)


local introspectionObj = {
	__schema = {
		description = nil,
		queryType = {
			name = "Query",
		},
		mutationType = nil,
		subscriptionType = nil,
		types = Array.concat(
			require(script.Parent["buildClientSchema.roblox.introspectionCommonTypes"]).introspection1And3Common,
			require(script.Parent["buildClientSchema.roblox.introspectionCommonTypes"]).allCommon
		),
		directives = {
			{
				name = "include",
				description = "Directs the executor to include this field or fragment only when the `if` argument is true.",
				isRepeatable = false,
				locations = {
					"FIELD",
					"FRAGMENT_SPREAD",
					"INLINE_FRAGMENT",
				},
				args = {
					{
						name = "if",
						description = "Included when true.",
						type = {
							kind = "NON_NULL",
							name = nil,
							ofType = {
								kind = "SCALAR",
								name = "Boolean",
								ofType = nil,
							},
						},
						defaultValue = nil,
						isDeprecated = false,
						deprecationReason = nil,
					},
				},
			},
			{
				name = "skip",
				description = "Directs the executor to skip this field or fragment when the `if` argument is true.",
				isRepeatable = false,
				locations = {
					"FIELD",
					"FRAGMENT_SPREAD",
					"INLINE_FRAGMENT",
				},
				args = {
					{
						name = "if",
						description = "Skipped when true.",
						type = {
							kind = "NON_NULL",
							name = nil,
							ofType = {
								kind = "SCALAR",
								name = "Boolean",
								ofType = nil,
							},
						},
						defaultValue = nil,
						isDeprecated = false,
						deprecationReason = nil,
					},
				},
			},
			{
				name = "deprecated",
				description = "Marks an element of a GraphQL schema as no longer supported.",
				isRepeatable = false,
				locations = {
					"FIELD_DEFINITION",
					"ARGUMENT_DEFINITION",
					"INPUT_FIELD_DEFINITION",
					"ENUM_VALUE",
				},
				args = {
					{
						name = "reason",
						description = "Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted using the Markdown syntax, as specified by {CommonMark}(https://commonmark.org/).",
						type = {
							kind = "SCALAR",
							name = "String",
							ofType = nil,
						},
						defaultValue = "\"No longer supported\"",
						isDeprecated = false,
						deprecationReason = nil,
					},
				},
			},
			{
				name = "specifiedBy",
				description = "Exposes a URL that specifies the behaviour of this scalar.",
				isRepeatable = false,
				locations = {
					"SCALAR",
				},
				args = {
					{
						name = "url",
						description = "The URL that specifies the behaviour of this scalar.",
						type = {
							kind = "NON_NULL",
							name = nil,
							ofType = {
								kind = "SCALAR",
								name = "String",
								ofType = nil,
							},
						},
						defaultValue = nil,
						isDeprecated = false,
						deprecationReason = nil,
					},
				},
			},
		},
	},
}

return introspectionObj
