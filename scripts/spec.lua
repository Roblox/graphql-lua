local Root = script.Parent.TestingBundle
local GraphQL = Root.GraphQL

local TestEZ = require(Root.Packages.Dev.TestEZ)

-- Run all tests, collect results, and report to stdout.
TestEZ.TestBootstrap:run(
	{ GraphQL },
	TestEZ.Reporters.TextReporter
)