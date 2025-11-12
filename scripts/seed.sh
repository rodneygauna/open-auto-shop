#!/bin/bash
# scripts/seed.sh
# Run seed data for development environment

set -e

echo "Running seed inside Docker container..."

# Run seed with Lapis environment set to development
sudo docker compose exec app sh -c "
    cd /app/app &&
    LAPIS_ENVIRONMENT=development /usr/local/openresty/luajit/bin/luajit -e 'require(\"seed\").run()'
"

echo "Seed completed!"
