-- app/migrations.lua
local db = require("lapis.db")
local schema = require("lapis.db.schema")

-- Define migration functions
local create_table, types
create_table, types = schema.create_table, schema.types

-- Return migration steps
return {
    -- Migration to create 'users' table
    [1762236897] = function(self)
        return create_table("users", {{"id", types.serial}, {
            "email",
            types.varchar,
            unique = true,
            null = false
        }, {
            "password_hash",
            types.varchar,
            null = false
        }, {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end
}
