-- app/config.lua
local config
config = require("lapis.config").config

-- Load environment variables
local pg_host = os.getenv("POSTGRES_HOST")
local pg_user = os.getenv("POSTGRES_USER")
local pg_pass = os.getenv("POSTGRES_PASSWORD")
local pg_db = os.getenv("POSTGRES_DB")
local secret_key = os.getenv("LAPIS_SECRET_KEY")

-- Confirm that PostgreSQL environment variables are set
if not (pg_host and pg_user and pg_pass and pg_db) then
    error("Missing required PostgreSQL environment variables")
end

-- Development configuration
return config("development", function()
    server("nginx")
    code_cache("off")
    num_workers(1)
    port(8080)
    session_name("autoshop_session_dev")
    secret(secret_key)
    return postgres(function()
        host(pg_host)
        user(pg_user)
        password(pg_pass)
        return database(pg_db)
    end)
end)
