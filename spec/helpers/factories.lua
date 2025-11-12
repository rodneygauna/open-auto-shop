-- spec/helpers/factories.lua
-- Factory functions for creating test data
local bcrypt = require("bcrypt")
local config = require("lapis.config").get()
local User = require("models.user")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")

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

-- Create a customer with default or custom attributes
function factories.create_customer(attrs)
    attrs = attrs or {}
    local count = next_counter()

    local customer_data = {
        first_name = attrs.first_name or "Customer",
        last_name = attrs.last_name or string.format("Test%d", count),
        middle_name = attrs.middle_name,
        suffix_name = attrs.suffix_name,
        email = attrs.email or string.format("customer%d@example.com", count),
        phone_number = attrs.phone_number or string.format("555111%04d", count),
        address1 = attrs.address1 or string.format("%d Test St", count),
        address2 = attrs.address2,
        city = attrs.city or "Test City",
        state = attrs.state or "TS",
        zip_code = attrs.zip_code or string.format("%05d", 10000 + count),
        notes = attrs.notes
    }

    return Customer:create(customer_data)
end

-- Create a vehicle with default or custom attributes
function factories.create_vehicle(attrs)
    attrs = attrs or {}
    local count = next_counter()

    local vehicle_data = {
        make = attrs.make or "Toyota",
        model = attrs.model or "Camry",
        year = attrs.year or 2020,
        vin = attrs.vin or string.format("VIN%013d", count),
        license_plate = attrs.license_plate or string.format("TEST%03d", count),
        color = attrs.color or "Blue",
        notes = attrs.notes
    }

    return Vehicle:create(vehicle_data)
end

return factories
