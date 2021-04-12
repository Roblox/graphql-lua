# GraphQL.lua

The Roblox Lua reference implementation for GraphQL, a query language for APIs created by Facebook.

[![Build Status](https://github.com/Roblox/graphql-lua/workflows/CI/badge.svg?branch=master)](https://github.com/Roblox/graphql-lua/actions?query=branch%3Amaster)
[![Coverage Status](https://codecov.io/gh/Roblox/graphql-lua/branch/master/graph/badge.svg)](https://codecov.io/gh/Roblox/graphql-lua)

See more complete documentation at https://graphql.org/ and
https://graphql.org/graphql-js/. GraphQL-Lua has few to no deviations from the upstream documentation and APIs, with the exception of the subscription API (which is stubbed). A quick search for `SKIP`ped tests will highlight current deviations.

Looking for help? Find resources [from the community](https://graphql.org/community/).

## Getting Started

A general overview of GraphQL is available in the
[README](https://github.com/graphql/graphql-spec/blob/master/README.md) for the
[Specification for GraphQL](https://github.com/graphql/graphql-spec). That overview
describes a simple set of GraphQL examples that __will__ exist as [tests](src/__tests__)
in this repository. A good way to get started with this repository is to walk
through that README and the corresponding tests in parallel.

### Using GraphQL.lua

This repository is currently under construction, with the goal of having an integration-tested GraphQL implementation written in Roblox Lua. See the README.md in each src subdirectory for current status, and run the tests using `scripts/ci.sh` to see the progress.

GraphQL.lua provides two important capabilities: building a type schema and
serving queries against that type schema.

First, build a GraphQL type schema which maps to your codebase.

```lua
local Workspace = Script.Parent.Parent
local graphql = require(Workspace.graphql)
local GraphQLSchema = graphql.GraphQLSchema
local GraphQLObjectType = graphql.GraphQLObjectType
local GraphQLString = graphql.GraphQLString

local schema = GraphQLSchema.new({
  query = GraphQLObjectType.new({
    name = 'RootQueryType',
    fields = {
      hello = {
        type = GraphQLString,
        resolve = function()
          return 'world';
        end,
      },
    },
  }),
});
```

This defines a simple schema, with one type and one field, that resolves
to a fixed value. The `resolve` function can return a value, a promise,
or an array of promises. A more complex example __will be__ included in the top-level [tests](src/__tests__) directory.

Then, serve the result of a query against that type schema.

```lua
local query = '{ hello }';

graphql(schema, query).then(function (result)
  --[[ Prints
    {
      data: { hello: "world" }
    }
  ]]
  print(tostring(result));
end)
```

This runs a query fetching the one field defined. The `graphql` function will
first ensure the query is syntactically and semantically valid before executing
it, reporting errors otherwise.

```lua
var query = '{ BoyHowdy }';

graphql(schema, query).then(function(result) 
  --[[ Prints
    {
      errors = {
        { message = 'Cannot query field BoyHowdy on RootQueryType',
          locations = { { line = 1, column = 3 } } }
      }
    }
  ]]
  print(tostring(result));
end)
```

**Note**: Please don't forget to set `_G.__DEV__` to false (the default) if you are running a production server. It will disable some checks that can be useful during development but will significantly improve performance.

### Want to ride the bleeding edge?

When this repository is ready for consumption, we will include instructions about how to reference it with rotriever and other appropriate tooling here. For now, pull the code and run the tests :)

### Using with GraphiQL and similar tooling

We are too early to document this, but will update this documentation with examples of integration with commodity GQL tooling in the future.

### Contributing

We actively welcome pull requests. Learn how to [contribute](./.github/CONTRIBUTING.md).

### Changelog

Changes are tracked as [GitHub releases](https://github.com/Roblox/graphql-lua/releases).

### License

GraphQL.lua is [MIT-licensed](./LICENSE).

### Credits

The Luau types in this project are based on [DefinitelyTyped](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/54712a7e28090c5b1253b746d1878003c954f3ff/types/graphql) definitions written by:

<!--- spell-checker:disable -->

- TonyYang https://github.com/TonyPythoneer
- Caleb Meredith https://github.com/calebmer
- Dominic Watson https://github.com/intellix
- Firede https://github.com/firede
- Kepennar https://github.com/kepennar
- Mikhail Novikov https://github.com/freiksenet
- Ivan Goncharov https://github.com/IvanGoncharov
- Hagai Cohen https://github.com/DxCx
- Ricardo Portugal https://github.com/rportugal
- Tim Griesser https://github.com/tgriesser
- Dylan Stewart https://github.com/dyst5422
- Alessio Dionisi https://github.com/adnsio
- Divyendu Singh https://github.com/divyenduz
- Brad Zacher https://github.com/bradzacher
- Curtis Layne https://github.com/clayne11
- Jonathan Cardoso https://github.com/JCMais
- Pavel Lang https://github.com/langpavel
- Mark Caudill https://github.com/mc0
- Martijn Walraven https://github.com/martijnwalraven
- Jed Mao https://github.com/jedmao
