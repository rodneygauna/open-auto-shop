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
        return create_table("users", {{"id", types.serial}, {"email", types.varchar({
            unique = true
        })}, {"password_hash", types.varchar}, {"first_name", types.varchar}, {"middle_name", types.varchar({
            null = true
        })}, {"last_name", types.varchar}, {"suffix_name", types.varchar({
            null = true
        })}, {"phone_number", types.varchar({
            null = true
        })}, {"title", types.varchar({
            null = true
        })}, {"is_admin", types.boolean({
            default = false
        })}, {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end
}
