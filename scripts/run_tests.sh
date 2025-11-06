#!/bin/bash
# scripts/run_tests.sh
# Script to run tests inside Docker container

set -e

echo "Running tests inside Docker container..."

# Run tests in Docker container with test environment
sudo docker compose exec app sh -c "
    cd /app &&
    export LUA_PATH='./app/?.lua;./app/?/init.lua;./spec/?.lua;./spec/?/init.lua;;' &&
    LAPIS_ENVIRONMENT=test busted $*
"

echo "Tests completed!"
