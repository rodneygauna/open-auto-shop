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
    end,
    -- Migration to create 'customers' table
    [1762438537] = function(self)
        return create_table("customers",
            {{"id", types.serial}, {"first_name", types.varchar}, {"middle_name", types.varchar({
                null = true
            })}, {"last_name", types.varchar}, {"suffix_name", types.varchar({
                null = true
            })}, {"phone_number", types.varchar({
                null = true
            })}, {"email", types.varchar()}, {"address1", types.varchar({
                null = true
            })}, {"address2", types.varchar({
                null = true
            })}, {"city", types.varchar({
                null = true
            })}, {"state", types.varchar({
                null = true
            })}, {"zip_code", types.varchar({
                null = true
            })}, {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end,
    -- Migration to create 'vehicles' table
    [1762438717] = function(self)
        return create_table("vehicles",
            {{"id", types.serial}, {"make", types.varchar}, {"model", types.varchar}, {"year", types.integer},
             {"vin", types.varchar({
                null = true
            })}, {"license_plate", types.varchar({
                null = true
            })}, {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end,
    -- Migration to create 'customers_vehicles' join table
    [1762438816] = function(self)
        return create_table("customers_vehicles",
            {{"id", types.serial}, {"customer_id", types.integer}, {"vehicle_id", types.integer},
             {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end,
    -- Migration to create 'business_info' table
    [1762438942] = function(self)
        return create_table("business_info",
            {{"id", types.serial}, {"name", types.varchar}, {"address1", types.varchar({
                null = true
            })}, {"address2", types.varchar({
                null = true
            })}, {"city", types.varchar({
                null = true
            })}, {"state", types.varchar({
                null = true
            })}, {"zip_code", types.varchar({
                null = true
            })}, {"phone_number", types.varchar({
                null = true
            })}, {"email", types.varchar({
                null = true
            })}, {"webiste", types.varchar}, {"created_at", types.time}, {"updated_at", types.time}, "PRIMARY KEY (id)"})
    end
}
