-- app/config.lua
local config = require("lapis.config")

-- Load environment variables
local pg_host = os.getenv("POSTGRES_HOST")
local pg_user = os.getenv("POSTGRES_USER")
local pg_pass = os.getenv("POSTGRES_PASSWORD")
local pg_db = os.getenv("POSTGRES_DB")
local secret_key = os.getenv("LAPIS_SECRET_KEY") or "please-change-me"

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
    postgres = {
        host = pg_host,
        user = pg_user,
        password = pg_pass,
        database = pg_db
    }
})
