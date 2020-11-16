#!/bin/bash

set -ex

rojo build test-bundle.project.json --output graphql.rbxmx

roblox-cli analyze default.project.json
roblox-cli run --load.model graphql.rbxmx --run scripts/spec.lua
