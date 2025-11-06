#!/bin/bash
# scripts/setup_test_db.sh
# Script to set up the test database

set -e

echo "Setting up test database..."

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Get database credentials
DB_USER="${POSTGRES_USER:-autoshop_user}"
TEST_DB="${POSTGRES_DB}_test"

echo "Creating database: $TEST_DB"
echo "Using PostgreSQL user: $DB_USER"

# Create test database
sudo docker compose exec -T postgres psql -U "$DB_USER" -d "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE $TEST_DB'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$TEST_DB')\gexec
EOSQL

echo "Test database created successfully!"

echo "Running migrations on test database..."

# Run migrations for test environment
sudo docker compose exec -T app sh -c "cd /app/app && LAPIS_ENVIRONMENT=test lapis migrate"

echo "Test database setup complete!"
echo "You can now run tests with: ./scripts/run_tests.sh"
