local Root = script.Parent.TestingBundle
local GraphQL = Root.GraphQL

local TestEZ = require(Root.Packages.Dev.TestEZ)

local function stripSpecSuffix(name)
	return (name:gsub("%.spec$", ""))
end

local function getPath(module, root)
	root = root or game

	local path = {}
	local last = module

	if last.Name == "init.spec" then
		-- Use the directory's node for init.spec files.
		last = last.Parent
	end

	while last ~= nil and last ~= root do
		table.insert(path, stripSpecSuffix(last.Name))
		last = last.Parent
	end
	table.insert(path, stripSpecSuffix(root.Name))

	return path
end

local function toStringPath(tablePath)
	local reversed = {}
	local length = #tablePath
	for i = 1, length do
		reversed[i] = tablePath[length - i + 1]
	end
	return table.concat(reversed, " ")
end

local modules = {}

for _, module in ipairs(GraphQL:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local name = module.Name
		if name:match(".spec$") and not name:match("fuzz.spec$") then
			local path = getPath(module, GraphQL)
			local pathString = toStringPath(path)
			table.insert(modules, {
				method = require(module),
				path = path,
				pathStringForSorting = pathString:lower()
			})
		end
	end
end

local plan = TestEZ.TestPlanner.createPlan(modules, nil, {})
local results = TestEZ.TestRunner.runPlan(plan)

TestEZ.Reporters.TextReporterQuiet.report(results)
