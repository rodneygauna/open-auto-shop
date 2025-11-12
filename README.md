# open-auto-shop

A customer and vehicle management system for auto repair shops built with Lapis (Lua web framework).

## Quick Start

### Development Setup

1. **Start the application:**

   ```bash
   sudo docker compose up -d
   ```

2. **Run migrations:**

   ```bash
   sudo docker compose exec app sh -c "cd /app/app && lapis migrate"
   ```

3. **Seed development data:**

   ```bash
   ./scripts/seed.sh
   ```

4. **Access the application:**
   - URL: <http://localhost:8080>
   - Admin Login: `admin@example.com` / `password123`
   - User Login: `mechanic@example.com` / `password123`

## Seed Data

The seed script (`app/seed.lua`) creates:

- 2 users (1 admin, 1 regular user)
- 1 business profile
- 3 customers
- 4 vehicles (associated with customers)

### Running Seeds

**Method 1: Using the shell script (recommended):**

```bash
./scripts/seed.sh
```

**Method 2: Using Lapis CLI:**

```bash
sudo docker compose exec app sh -c "cd /app/app && lapis exec ../scripts/seed_cli.lua"
```

**Method 3: Direct Lua execution:**

```bash
sudo docker compose exec app sh -c "cd /app/app && LAPIS_ENVIRONMENT=development lua -e 'require(\"seed\").run()'"
```

### Safety Features

- Seeds only run in `development` environment
- Automatically clears existing data before seeding
- Respects foreign key constraints
- Provides detailed console output

## Testing

Run the test suite:

```bash
./scripts/run_tests.sh
```

See `TESTING.md` for detailed testing documentation.

## Project Structure

```text
app/
├── controllers/     # Route handlers
├── models/         # Database models
├── views/          # Templates (organized by feature)
│   ├── auth/
│   ├── business/
│   ├── customers/
│   ├── vehicles/
│   └── settings/
├── config.lua      # Environment configuration
├── migrations.lua  # Database migrations
└── seed.lua        # Development seed data

scripts/
├── seed.sh         # Seed data script
├── run_tests.sh    # Test runner
└── setup_test_db.sh # Test database setup

spec/               # Test files
└── helpers/        # Test helper functions
```
