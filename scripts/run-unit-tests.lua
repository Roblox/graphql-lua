--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
local Root = script.Parent.TestingBundle
local GraphQL = Root.Packages.GraphQL

local TestEZ = require(Root.Packages.Dev.JestGlobals).TestEZ

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
				pathStringForSorting = pathString:lower(),
			})
		end
	end
end

local plan = TestEZ.TestPlanner.createPlan(modules, nil, {})
local results = TestEZ.TestRunner.runPlan(plan)

TestEZ.Reporters.TextReporterQuiet.report(results)

return {}
