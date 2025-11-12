-- spec/helpers/factories.lua
-- Factory functions for creating test data
local bcrypt = require("bcrypt")
local config = require("lapis.config").get()
local User = require("models.user")

local factories = {}

-- Counter to ensure unique values
local counter = 0

-- Get next unique counter value
local function next_counter()
    counter = counter + 1
    return counter
end

-- Reset counter (useful between tests)
function factories.reset_counter()
    counter = 0
end

-- Create a user with default or custom attributes
function factories.create_user(attrs)
    attrs = attrs or {}
    local count = next_counter()

    local user_data = {
        email = attrs.email or string.format("user%d@example.com", count),
        password_hash = attrs.password_hash or bcrypt.digest(attrs.password or "password123", config.bcrypt_rounds),
        first_name = attrs.first_name or "Test",
        last_name = attrs.last_name or string.format("User%d", count),
        middle_name = attrs.middle_name,
        suffix_name = attrs.suffix_name,
        phone_number = attrs.phone_number or string.format("555000%04d", count),
        title = attrs.title,
        is_admin = attrs.is_admin or false
    }

    return User:create(user_data)
end

-- Build user data without saving to database
-- Note: Uses 'phone' (form field name) instead of 'phone_number' (database column name)
function factories.build_user_data(attrs)
    attrs = attrs or {}
    local count = next_counter()

    return {
        email = attrs.email or string.format("user%d@example.com", count),
        password = attrs.password or "password123",
        confirm_password = attrs.confirm_password or attrs.password or "password123",
        first_name = attrs.first_name or "Test",
        last_name = attrs.last_name or string.format("User%d", count),
        middle_name = attrs.middle_name or "",
        suffix_name = attrs.suffix_name or "",
        phone = attrs.phone or attrs.phone_number or string.format("555-000-%04d", count),
        title = attrs.title or ""
    }
end

return factories
