-- spec/helpers/db.lua
-- Database helper functions for tests
local lapis_config = require("lapis.config")
local db = require("lapis.db")

local db_helpers = {}

-- Truncate specified tables
-- Only works in test environment for safety
function db_helpers.truncate_tables(tables)
    local env = lapis_config.get()._name

    if env ~= "test" then
        error("truncate_tables can only be run in test environment")
    end

    for _, table_name in ipairs(tables) do
        db.query("TRUNCATE TABLE " .. db.escape_identifier(table_name) .. " CASCADE")
    end
end

-- Clear all test data from common tables
function db_helpers.clear_test_data()
    db_helpers.truncate_tables({"users", "lapis_migrations" -- Keep migrations table but can be cleared if needed
    })
end

return db_helpers
