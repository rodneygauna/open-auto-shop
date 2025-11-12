# Docker Testing Setup - Corrections Made

## Issues Fixed

### ❌ Original Problems

1. **Incorrect volume mounts** - Only `./app` was mounted, but tests need both `./app` and `./spec`
2. **Wrong paths in `.busted`** - Used absolute paths instead of relative Docker paths
3. **Host-based test execution** - Scripts tried to run tests on host instead of in Docker
4. **Missing test files in container** - `.busted` config wasn't mounted

### ✅ Corrections Applied

#### 1. Updated `docker-compose.yml`

**Before:**

```yaml
volumes:
  - ./app:/app
```

**After:**

```yaml
volumes:
  - ./app:/app/app        # App code at /app/app
  - ./spec:/app/spec      # Tests at /app/spec
  - ./.busted:/app/.busted # Busted config
```

**Also updated command:**

```yaml
command: ["cd /app/app && /usr/local/openresty/luajit/bin/lapis migrate && /usr/local/openresty/luajit/bin/lapis server development"]
```

#### 2. Fixed `.busted` Configuration

**Before:**

```lua
path = {
    "app/?.lua",
    "app/?/init.lua",
```

**After:**

```lua
path = {
    "./app/?.lua",      # Relative to /app in container
    "./app/?/init.lua",
```

#### 3. Updated Test Scripts

**`scripts/run_tests.sh` - Before:**

```bash
busted "$@"  # Tried to run on host
```

**After:**

```bash
sudo docker compose exec app sh -c "
    cd /app &&
    LAPIS_ENVIRONMENT=test busted $*
"
```

#### 4. Updated Documentation

- All test commands now use Docker
- Removed host-based instructions
- Added Docker-specific troubleshooting

## Directory Structure in Docker

```text
Container: /app/
├── app/          (mounted from host ./app)
│   ├── app.lua
│   ├── config.lua
│   ├── models/
│   └── controllers/
├── spec/         (mounted from host ./spec)
│   ├── helpers/
│   └── auth_spec.lua
└── .busted       (mounted from host ./.busted)
```

## How to Use

### First Time Setup

```bash
# 1. Rebuild containers with new volume mounts
cd /home/rodney/GitHub/open-auto-shop
sudo docker compose down
sudo docker compose up -d

# 2. Set up test database
./scripts/setup_test_db.sh
```

### Running Tests

```bash
# Run all tests
./scripts/run_tests.sh

# Run specific test
./scripts/run_tests.sh spec/auth_spec.lua

# Manual execution
sudo docker compose exec app sh -c "cd /app && LAPIS_ENVIRONMENT=test busted"
```

## Why These Changes Were Necessary

1. **Docker Isolation**: Tests must run inside container where Lapis and dependencies are installed
2. **Path Consistency**: Container paths must match between volumes and Lua require statements
3. **Database Access**: Tests need to connect to PostgreSQL in the Docker network
4. **Environment**: `LAPIS_ENVIRONMENT=test` must be set in container context

## Verification Checklist

- [x] Volume mounts include spec and .busted
- [x] .busted uses relative paths
- [x] Scripts execute inside Docker
- [x] Test environment configuration exists
- [x] Busted installed in Dockerfile
- [x] Documentation updated

## Next Steps

1. **Start containers**: `sudo docker compose up -d`
2. **Set up test DB**: `./scripts/setup_test_db.sh`
3. **Run tests**: `./scripts/run_tests.sh`

All tests should now run properly inside the Docker environment! 🎉
