# Quick Testing Reference

## First Time Setup

```bash
# 1. Make sure containers are running
sudo docker compose up -d

# 2. Set up test database
./scripts/setup_test_db.sh
```

## Running Tests

```bash
# Run all tests
./scripts/run_tests.sh

# Run with verbose output
./scripts/run_tests.sh -v

# Run specific test file
./scripts/run_tests.sh spec/auth_spec.lua

# Run tests manually
sudo docker compose exec app sh -c "cd /app && LAPIS_ENVIRONMENT=test busted"
```

## Common Commands

```bash
# Rebuild containers after changes
sudo docker compose down -v && sudo docker compose up --build -d

# Reset test database
sudo docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS open_auto_shop_test;"
./scripts/setup_test_db.sh

# View test database
sudo docker compose exec postgres psql -U postgres -d open_auto_shop_test

# Check container logs
sudo docker compose logs app

# Access app container shell
sudo docker compose exec app bash
```

## Project Structure

```text
/home/rodney/GitHub/open-auto-shop/
├── app/                    # Lapis application code
│   ├── app.lua            # Main application
│   ├── config.lua         # Environment configs (dev, prod, test)
│   ├── models/            # Database models
│   └── controllers/       # Route controllers
├── spec/                  # Test files
│   ├── helpers/           # Test helpers
│   │   ├── factories.lua  # Factory functions
│   │   ├── db.lua         # Database helpers
│   │   └── request.lua    # Request helpers
│   └── auth_spec.lua      # Authentication tests
├── scripts/               # Helper scripts
│   ├── setup_test_db.sh   # Set up test database
│   └── run_tests.sh       # Run tests
└── .busted                # Busted configuration
```

## Inside Docker Container

```text
/app/
├── app/                   # App code (mounted from host ./app)
├── spec/                  # Tests (mounted from host ./spec)
└── .busted                # Config (mounted from host)
```

## Environment Variables

Tests use the `test` environment configuration which automatically:

- Uses `{POSTGRES_DB}_test` database
- Sets `code_cache = "off"` for development
- Uses a separate session name

## Troubleshooting

### Tests fail with "module not found"

- Ensure `.busted` is mounted in docker-compose.yml
- Verify containers are running: `sudo docker compose ps`

### Database connection errors

- Check `.env` file has all POSTGRES_* variables
- Verify test database exists: `./scripts/setup_test_db.sh`

### CSRF token errors

- Use helper functions in `spec/helpers/request.lua`
- Ensure session handling in mock requests

### Tests pass but changes not reflected

- Restart containers: `sudo docker compose restart app`
- Clear code cache (automatic in test mode)
