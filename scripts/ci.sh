#!/bin/bash

set -x

echo "Remove .robloxrc from dev dependencies"
find Packages/Dev -name "*.robloxrc" | xargs rm -f
find Packages/_Index -name "*.robloxrc" | xargs rm -f

roblox-cli analyze test-bundle.project.json
selene src
stylua -c src
roblox-cli run --load.model test-bundle.project.json --run scripts/run-unit-tests.lua --fastFlags.allOnLuau --fastFlags.overrides "EnableLoadModule=true"
