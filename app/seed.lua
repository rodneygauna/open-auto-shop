-- app/seed.lua
-- Seed data for development environment
local config = require("lapis.config").get()
local bcrypt = require("bcrypt")

-- Import models
local User = require("models.user")
local Business = require("models.business")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local CustomersVehicles = require("models.customers_vehicles")

local seed = {}

-- Only allow seeding in development environment
function seed.check_environment()
    if config._name ~= "development" then
        error("Seeding is only allowed in development environment!")
    end
    print("✓ Environment check passed: " .. config._name)
end

-- Clear all existing data
function seed.clear_data()
    print("\n🗑️  Clearing existing data...")

    -- Order matters due to foreign key constraints
    local db = require("lapis.db")
    db.query("TRUNCATE TABLE customers_vehicles CASCADE")
    db.query("TRUNCATE TABLE vehicles CASCADE")
    db.query("TRUNCATE TABLE customers CASCADE")
    db.query("TRUNCATE TABLE business_info CASCADE")
    db.query("TRUNCATE TABLE users CASCADE")

    print("✓ Data cleared")
end

-- Seed users
function seed.create_users()
    print("\n👤 Creating users...")

    local users = {{
        email = "admin@example.com",
        password = "password123",
        first_name = "Admin",
        last_name = "User",
        phone_number = "5551234567",
        is_admin = true
    }, {
        email = "mechanic@example.com",
        password = "password123",
        first_name = "Mike",
        last_name = "Mechanic",
        phone_number = "5559876543",
        is_admin = false
    }}

    local created_users = {}
    for i, user_data in ipairs(users) do
        local user = User:create({
            email = user_data.email,
            password_hash = bcrypt.digest(user_data.password, 12),
            first_name = user_data.first_name,
            last_name = user_data.last_name,
            phone_number = user_data.phone_number,
            is_admin = user_data.is_admin
        })
        created_users[i] = user
        print(string.format("  ✓ Created user: %s (%s)", user.email, user.is_admin and "admin" or "user"))
    end

    return created_users
end

-- Seed business
function seed.create_business()
    print("\n🏢 Creating business...")

    local business = Business:create({
        name = "Quick Fix Auto Shop",
        address1 = "123 Main Street",
        address2 = "Suite 100",
        city = "Springfield",
        state = "IL",
        zip_code = "62701",
        phone_number = "5555551234",
        email = "info@quickfixauto.com",
        website = "https://quickfixauto.com"
    })

    print(string.format("  ✓ Created business: %s", business.name))
    return business
end

-- Seed customers
function seed.create_customers()
    print("\n👥 Creating customers...")

    local customers_data = {{
        first_name = "John",
        last_name = "Smith",
        phone_number = "5551001001",
        email = "john.smith@email.com",
        address1 = "456 Oak Avenue",
        city = "Springfield",
        state = "IL",
        zip_code = "62702"
    }, {
        first_name = "Sarah",
        middle_name = "Jane",
        last_name = "Johnson",
        phone_number = "5551002002",
        email = "sarah.johnson@email.com",
        address1 = "789 Elm Street",
        address2 = "Apt 4B",
        city = "Springfield",
        state = "IL",
        zip_code = "62703"
    }, {
        first_name = "Robert",
        last_name = "Williams",
        suffix_name = "Jr.",
        phone_number = "5551003003",
        email = "rob.williams@email.com",
        address1 = "321 Pine Road",
        city = "Springfield",
        state = "IL",
        zip_code = "62704"
    }}

    local customers = {}
    for i, customer_data in ipairs(customers_data) do
        local customer = Customer:create(customer_data)
        customers[i] = customer
        print(string.format("  ✓ Created customer: %s %s", customer.first_name, customer.last_name))
    end

    return customers
end

-- Seed vehicles
function seed.create_vehicles(customers)
    print("\n🚗 Creating vehicles...")

    local vehicles_data = {{
        make = "Toyota",
        model = "Camry",
        year = 2020,
        vin = "1HGBH41JXMN109186",
        license_plate = "ABC123",
        color = "Silver",
        customer_index = 1
    }, {
        make = "Honda",
        model = "Civic",
        year = 2019,
        vin = "2HGFG12878H123456",
        license_plate = "XYZ789",
        color = "Blue",
        customer_index = 2
    }, {
        make = "Ford",
        model = "F-150",
        year = 2021,
        vin = "1FTFW1E84MKE12345",
        license_plate = "DEF456",
        color = "Black",
        customer_index = 2
    }, {
        make = "Chevrolet",
        model = "Silverado",
        year = 2018,
        vin = "1GCVKREC4JZ123456",
        license_plate = "GHI789",
        color = "Red",
        customer_index = 3
    }}

    local vehicles = {}
    for i, vehicle_data in ipairs(vehicles_data) do
        local customer_index = vehicle_data.customer_index
        vehicle_data.customer_index = nil

        local vehicle = Vehicle:create(vehicle_data)
        vehicles[i] = vehicle

        -- Associate vehicle with customer
        CustomersVehicles:create({
            customer_id = customers[customer_index].id,
            vehicle_id = vehicle.id
        })

        print(string.format("  ✓ Created vehicle: %s %s %s (assigned to %s %s)", vehicle.year, vehicle.make,
            vehicle.model, customers[customer_index].first_name, customers[customer_index].last_name))
    end

    return vehicles
end

-- Run all seed functions
function seed.run()
    print("\n🌱 Starting seed process...\n")
    print("=" .. string.rep("=", 60))

    seed.check_environment()
    seed.clear_data()

    local users = seed.create_users()
    local business = seed.create_business()
    local customers = seed.create_customers()
    local vehicles = seed.create_vehicles(customers)

    print("\n" .. string.rep("=", 60))
    print("\n✅ Seed completed successfully!")
    print("\nLogin credentials:")
    print("  Admin: admin@example.com / password123")
    print("  User:  mechanic@example.com / password123")
    print("\n")
end

return seed
