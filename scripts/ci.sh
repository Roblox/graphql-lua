#!/bin/bash

set -ex

rojo build test-bundle.project.json --output graphql-tests.rbxm

echo "Remove .robloxrc from dev dependencies"
find Packages/Dev -name "*.robloxrc" | xargs rm -f
find Packages/_Index -name "*.robloxrc" | xargs rm -f

roblox-cli analyze test-bundle.project.json
selene src

roblox-cli run --load.model graphql-tests.rbxm --run scripts/run-unit-tests.lua
