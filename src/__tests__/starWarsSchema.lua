-- upstream: -- upstream: https://github.com/graphql/graphql-js/blob/1611bbb08a88f734e9490b14cfe6afea11a838e0/src/__tests__/starWarsSchema.js
local rootWorkspace = script.Parent.Parent
local Packages = rootWorkspace.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
type Array<T> = LuauPolyfill.Array<T>

local invariant = require(rootWorkspace.jsutils.invariant).invariant

local GraphQLSchema = require(rootWorkspace.type.schema).GraphQLSchema
local GraphQLString = require(rootWorkspace.type.scalars).GraphQLString
local definitionModule = require(rootWorkspace.type.definition)
local GraphQLList = definitionModule.GraphQLList
local GraphQLNonNull = definitionModule.GraphQLNonNull
local GraphQLEnumType = definitionModule.GraphQLEnumType
local GraphQLInterfaceType = definitionModule.GraphQLInterfaceType
local GraphQLObjectType = definitionModule.GraphQLObjectType

local starWarsDataModule = require(script.Parent.starWarsData)
local getFriends = starWarsDataModule.getFriends
local getHero = starWarsDataModule.getHero
local getHuman = starWarsDataModule.getHuman
local getDroid = starWarsDataModule.getDroid

local characterInterface, humanType, droidType

--[[*
 * This is designed to be an end-to-end test, demonstrating
 * the full GraphQL stack.
 *
 * We will create a GraphQL schema that describes the major
 * characters in the original Star Wars trilogy.
 *
 * NOTE: This may contain spoilers for the original Star
 * Wars trilogy.
 ]]

--[[*
 * Using our shorthand to describe type systems, the type system for our
 * Star Wars example is:
 *
 * enum Episode { NEW_HOPE, EMPIRE, JEDI }
 *
 * interface Character {
 *   id: String!
 *   name: String
 *   friends: [Character]
 *   appearsIn: [Episode]
 * }
 *
 * type Human implements Character {
 *   id: String!
 *   name: String
 *   friends: [Character]
 *   appearsIn: [Episode]
 *   homePlanet: String
 * }
 *
 * type Droid implements Character {
 *   id: String!
 *   name: String
 *   friends: [Character]
 *   appearsIn: [Episode]
 *   primaryFunction: String
 * }
 *
 * type Query {
 *   hero(episode: Episode): Character
 *   human(id: String!): Human
 *   droid(id: String!): Droid
 * }
 *
 * We begin by setting up our schema.
 ]]

--[[*
 * The original trilogy consists of three movies.
 *
 * This implements the following type system shorthand:
 *   enum Episode { NEW_HOPE, EMPIRE, JEDI }
 ]]
local episodeEnum = GraphQLEnumType.new({
	name = "Episode",
	description = "One of the films in the Star Wars Trilogy",
	values = {
		NEW_HOPE = {
			value = 4,
			description = "Released in 1977.",
		},
		EMPIRE = {
			value = 5,
			description = "Released in 1980.",
		},
		JEDI = {
			value = 6,
			description = "Released in 1983.",
		},
	},
})

--[[*
 * Characters in the Star Wars trilogy are either humans or droids.
 *
 * This implements the following type system shorthand:
 *   interface Character {
 *     id: String!
 *     name: String
 *     friends: [Character]
 *     appearsIn: [Episode]
 *     secretBackstory: String
 *   }
 ]]
characterInterface = GraphQLInterfaceType.new({
	name = "Character",
	description = "A character in the Star Wars Trilogy",
	fields = function()
		return {
			id = {
				type = GraphQLNonNull.new(GraphQLString),
				description = "The id of the character.",
			},
			name = {
				type = GraphQLString,
				description = "The name of the character.",
			},
			friends = {
				type = GraphQLList.new(characterInterface),
				description = "The friends of the character, or an empty list if they have none.",
			},
			appearsIn = {
				type = GraphQLList.new(episodeEnum),
				description = "Which movies they appear in.",
			},
			secretBackstory = {
				type = GraphQLString,
				description = "All secrets about their past.",
			},
		}
	end,
	resolveType = function(character)
		if character.type == "Human" then
			return humanType.name
		elseif character.type == "Droid" then
			return droidType.name
		end

		-- istanbul ignore next (Not reachable. All possible types have been considered)
		invariant(false)
		return nil
	end,
})

--[[*
 * We define our human type, which implements the character interface.
 *
 * This implements the following type system shorthand:
 *   type Human : Character {
 *     id: String!
 *     name: String
 *     friends: [Character]
 *     appearsIn: [Episode]
 *     secretBackstory: String
 *   }
 ]]
humanType = GraphQLObjectType.new({
	name = "Human",
	description = "A humanoid creature in the Star Wars universe.",
	fields = function()
		return {
			id = {
				type = GraphQLNonNull.new(GraphQLString),
				description = "The id of the human.",
			},
			name = {
				type = GraphQLString,
				description = "The name of the human.",
			},
			friends = {
				type = GraphQLList.new(characterInterface),
				description = "The friends of the human, or an empty list if they have none.",
				resolve = function(human)
					return getFriends(human)
				end,
			},
			appearsIn = {
				type = GraphQLList.new(episodeEnum),
				description = "Which movies they appear in.",
			},
			homePlanet = {
				type = GraphQLString,
				description = "The home planet of the human, or null if unknown.",
			},
			secretBackstory = {
				type = GraphQLString,
				description = "Where are they from and how they came to be who they are.",
				resolve = function()
					error(Error("secretBackstory is secret."))
				end,
			},
		}
	end,
	interfaces = { characterInterface },
})

--[[*
 * The other type of character in Star Wars is a droid.
 *
 * This implements the following type system shorthand:
 *   type Droid : Character {
 *     id: String!
 *     name: String
 *     friends: [Character]
 *     appearsIn: [Episode]
 *     secretBackstory: String
 *     primaryFunction: String
 *   }
 ]]
droidType = GraphQLObjectType.new({
	name = "Droid",
	description = "A mechanical creature in the Star Wars universe.",
	fields = function()
		return {
			id = {
				type = GraphQLNonNull.new(GraphQLString),
				description = "The id of the droid.",
			},
			name = {
				type = GraphQLString,
				description = "The name of the droid.",
			},
			friends = {
				type = GraphQLList.new(characterInterface),
				description = "The friends of the droid, or an empty list if they have none.",
				resolve = function(droid)
					return getFriends(droid)
				end,
			},
			appearsIn = {
				type = GraphQLList.new(episodeEnum),
				description = "Which movies they appear in.",
			},
			secretBackstory = {
				type = GraphQLString,
				description = "Construction date and the name of the designer.",
				resolve = function()
					error(Error("secretBackstory is secret."))
				end,
			},
			primaryFunction = {
				type = GraphQLString,
				description = "The primary function of the droid.",
			},
		}
	end,
	interfaces = { characterInterface },
})

--[[*
 * This is the type that will be the root of our query, and the
 * entry point into our schema. It gives us the ability to fetch
 * objects by their IDs, as well as to fetch the undisputed hero
 * of the Star Wars trilogy, R2-D2, directly.
 *
 * This implements the following type system shorthand:
 *   type Query {
 *     hero(episode: Episode): Character
 *     human(id: String!): Human
 *     droid(id: String!): Droid
 *   }
 *
 ]]
local queryType = GraphQLObjectType.new({
	name = "Query",
	fields = function()
		return {
			hero = {
				type = characterInterface,
				args = {
					episode = {
						description = "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.",
						type = episodeEnum,
					},
				},
				resolve = function(_source, arg)
					return getHero(arg.episode)
				end,
			},
			human = {
				type = humanType,
				args = {
					id = {
						description = "id of the human",
						type = GraphQLNonNull.new(GraphQLString),
					},
				},
				resolve = function(_source, arg)
					return getHuman(arg.id)
				end,
			},
			droid = {
				type = droidType,
				args = {
					id = {
						description = "id of the droid",
						type = GraphQLNonNull.new(GraphQLString),
					},
				},
				resolve = function(_source, arg)
					return getDroid(arg.id)
				end,
			},
		}
	end,
})

--[[*
 * Finally, we construct our schema (whose starting query type is the query
 * type we defined above) and export it.
 ]]
return {
	StarWarsSchema = GraphQLSchema.new({
		query = queryType,
		types = { humanType, droidType },
	}),
}
