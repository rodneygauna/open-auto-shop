-- app/config.lua
local config = require("lapis.config")

-- Load environment variables
local pg_host = os.getenv("POSTGRES_HOST")
local pg_user = os.getenv("POSTGRES_USER")
local pg_pass = os.getenv("POSTGRES_PASSWORD")
local pg_db = os.getenv("POSTGRES_DB")
local secret_key = os.getenv("LAPIS_SECRET_KEY") or "please-change-me"

-- Security constants
local BCRYPT_ROUNDS = tonumber(os.getenv("BCRYPT_ROUNDS")) or 12
local BUSINESS_ID = 1 -- Only one business per instance

-- Pagination constants
local ITEMS_PER_PAGE = tonumber(os.getenv("ITEMS_PER_PAGE")) or 20

-- Validate that PostgreSQL environment variables are set
if not (pg_host and pg_user and pg_pass and pg_db) then
    error(
        "Missing required PostgreSQL environment variables: POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB")
end

-- Warn if using default secret key
if secret_key == "please-change-me" then
    print("WARNING: Using default secret key. Set LAPIS_SECRET_KEY environment variable for production!")
end

-- Development configuration
config("development", {
    server = "nginx",
    code_cache = "off",
    num_workers = 1,
    port = 8080,
    session_name = "autoshop_session_dev",
    secret = secret_key,
    bcrypt_rounds = BCRYPT_ROUNDS,
    business_id = BUSINESS_ID,
    items_per_page = ITEMS_PER_PAGE,
    postgres = {
        host = pg_host,
        user = pg_user,
        password = pg_pass,
        database = pg_db
    }
})

-- Production configuration
config("production", {
    server = "nginx",
    code_cache = "on",
    num_workers = 4,
    port = 8080,
    session_name = "autoshop_session_prod",
    secret = secret_key,
    bcrypt_rounds = BCRYPT_ROUNDS,
    business_id = BUSINESS_ID,
    items_per_page = ITEMS_PER_PAGE,
    postgres = {
        host = pg_host,
        user = pg_user,
        password = pg_pass,
        database = pg_db
    }
})

-- Test configuration
config("test", {
    server = "nginx",
    code_cache = "off",
    num_workers = 1,
    port = 8080,
    session_name = "autoshop_session_test",
    secret = "test-secret-key-do-not-use-in-production",
    bcrypt_rounds = 4, -- Lower rounds for faster tests
    business_id = BUSINESS_ID,
    items_per_page = ITEMS_PER_PAGE,
    postgres = {
        host = pg_host or "127.0.0.1",
        user = pg_user or "postgres",
        password = pg_pass or "postgres",
        database = pg_db and (pg_db .. "_test") or "open_auto_shop_test"
    }
})
