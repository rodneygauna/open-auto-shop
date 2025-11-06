# Testing Guide

This project uses [Busted](http://olivinelabs.com/busted/) for testing with the Lapis testing framework.

## Prerequisites

All testing dependencies are pre-installed in the Docker container:

- Busted (test framework)
- Lapis (web framework)
- PostgreSQL drivers

**Note:** Tests are run inside Docker containers, not on your host machine.

## Test Database Setup

The tests use a separate database to avoid affecting your development data. The test database is automatically configured in `config.lua` under the `test` environment.

### Create Test Database

Before running tests, create the test database:

```bash
# Connect to PostgreSQL
sudo docker compose exec postgres psql -U postgres

# Create the test database
CREATE DATABASE open_auto_shop_test;

# Grant permissions (if needed)
GRANT ALL PRIVILEGES ON DATABASE open_auto_shop_test TO postgres;

# Exit
\q
```

### Run Migrations for Test Database

```bash
# Run migrations inside Docker container
sudo docker compose exec app sh -c "cd /app/app && LAPIS_ENVIRONMENT=test lapis migrate"
```

## Running Tests

**Important:** All tests must be run inside the Docker container.

### Run All Tests

```bash
# Using the helper script (recommended)
./scripts/run_tests.sh

# Or run directly with docker compose
sudo docker compose exec app sh -c "cd /app && LAPIS_ENVIRONMENT=test busted"

# With verbose output
./scripts/run_tests.sh -v
```

### Run Specific Test File

```bash
# Run specific test file
sudo docker compose exec app sh -c "cd /app && LAPIS_ENVIRONMENT=test busted spec/auth_spec.lua"

# Or with the helper script
./scripts/run_tests.sh spec/auth_spec.lua
```

### Run Tests with Coverage

```bash
sudo docker compose exec app sh -c "cd /app && LAPIS_ENVIRONMENT=test busted --coverage"
```

## Test Structure

```text
spec/
├── helpers/
│   ├── factories.lua    # Factory functions for creating test data
│   ├── db.lua           # Database helper functions
│   └── request.lua      # Request helper functions
└── auth_spec.lua        # Authentication tests
```

## Writing Tests

### Example Test Structure

```lua
local mock_request = require("lapis.spec.request").mock_request
local app = require("app")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("My Feature", function()
    before_each(function()
        -- Clean database before each test
        db_helpers.truncate_tables({"users"})
        factories.reset_counter()
    end)

    it("should do something", function()
        local status, body = mock_request(app, "/path")
        assert.equal(200, status)
    end)
end)
```

### Using Factories

```lua
-- Create a user in the database
local user = factories.create_user({
    email = "test@example.com",
    password = "password123"
})

-- Build user data without saving
local user_data = factories.build_user_data({
    email = "test@example.com"
})
```

### Testing Authentication

The authentication tests demonstrate:

- GET/POST request handling
- CSRF token validation
- Form validation
- Database interactions
- Session management
- Redirect flows

## Common Issues

### Database Connection Errors

Make sure your `.env` file contains all required PostgreSQL environment variables. These are automatically passed to the Docker container.

### Module Not Found Errors

Ensure:

1. Docker containers are running (`sudo docker compose up -d`)
2. The `.busted` configuration file is mounted in the container
3. Tests are run from `/app` directory inside the container

### CSRF Token Errors

The test helpers in `spec/helpers/request.lua` provide functions to handle CSRF tokens automatically.

## Continuous Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Set up test database
  run: ./scripts/setup_test_db.sh

- name: Run Tests
  run: ./scripts/run_tests.sh -v
```

## Best Practices

1. **Isolate Tests**: Each test should be independent and not rely on other tests
2. **Clean Up**: Use `before_each` to truncate tables and reset state
3. **Use Factories**: Create test data with factories for consistency
4. **Test Edge Cases**: Test both success and failure scenarios
5. **Descriptive Names**: Use clear, descriptive test names
6. **Test Environment**: Always use the `test` environment to protect your data

## Additional Resources

- [Lapis Testing Documentation](https://leafo.net/lapis/reference/testing.html)
- [Busted Documentation](http://olivinelabs.com/busted/)
- [Lua Assertions](http://olivinelabs.com/busted/#asserts)
