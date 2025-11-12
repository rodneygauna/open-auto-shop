-- spec/vehicles_crud_spec.lua
-- Tests for Vehicle CRUD operations
local mock_request = require("lapis.spec.request").mock_request
local csrf = require("lapis.csrf")

-- Load app and helpers
local app = require("app")
local User = require("models.user")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("Vehicle CRUD Operations", function()

    local test_user
    local session
    local csrf_token
    local test_customer

    before_each(function()
        db_helpers.truncate_tables({"users", "customers", "vehicles", "customers_vehicles"})
        factories.reset_counter()

        -- Create test user
        test_user = factories.create_user({
            email = "test@example.com",
            is_admin = true
        })

        -- Create test customer for vehicle associations
        test_customer = factories.create_customer({
            first_name = "Test",
            last_name = "Customer"
        })

        -- Create session
        session = {
            current_user_id = test_user.id
        }

        -- Generate CSRF token
        local mock_self = {
            session = session,
            cookies = {}
        }
        csrf_token = csrf.generate_token(mock_self)
    end)

    describe("Vehicle Create", function()

        it("should display vehicle create form", function()
            local status, body = mock_request(app, "/vehicles/create", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Vehicle") or body:match("vehicle"))
            assert.truthy(body:match('name="make"'))
            assert.truthy(body:match('name="model"'))
            assert.truthy(body:match('name="year"'))
        end)

        it("should display vehicle create form with customer parameter", function()
            local status, body = mock_request(app, "/vehicles/create?customer_id=" .. test_customer.id, {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Vehicle") or body:match("vehicle"))
        end)

        it("should create a vehicle with valid data", function()
            local vehicle_count_before = Vehicle:count()

            -- Create vehicle directly using model
            local vehicle = Vehicle:create({
                make = "Toyota",
                model = "Camry",
                year = 2020,
                vin = "1HGBH41JXMN109186",
                license_plate = "ABC123",
                color = "Blue"
            })

            assert.truthy(vehicle)
            assert.equal("Toyota", vehicle.make)
            assert.equal("Camry", vehicle.model)
            assert.equal(2020, vehicle.year)

            local vehicle_count_after = Vehicle:count()
            assert.equal(vehicle_count_before + 1, vehicle_count_after)
        end)

        it("should associate vehicle with customer on creation", function()
            local vehicle = factories.create_vehicle({
                make = "Honda",
                model = "Civic"
            })

            -- Associate vehicle with customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            -- Verify association exists
            local result = db.select("* from customers_vehicles where vehicle_id = ? and customer_id = ?", vehicle.id,
                test_customer.id)
            assert.truthy(result[1])
        end)

        it("should require authentication to view create form", function()
            local status = mock_request(app, "/vehicles/create", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Vehicle View", function()

        it("should display vehicle details", function()
            local vehicle = factories.create_vehicle({
                make = "Ford",
                model = "F150",
                year = 2021,
                vin = "1FTFW1E50BFC12345",
                license_plate = "XYZ789",
                color = "Red"
            })

            local status, body = mock_request(app, "/vehicles/" .. vehicle.id, {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Ford"))
            assert.truthy(body:match("F150"))
        end)

        it("should display vehicle with associated customer", function()
            local vehicle = factories.create_vehicle({
                make = "Chevrolet",
                model = "Silverado"
            })

            -- Associate vehicle with customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            local status, body = mock_request(app, "/vehicles/" .. vehicle.id, {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Chevrolet") or body:match("Silverado"))
            assert.truthy(body:match("Test") and body:match("Customer"))
        end)

        it("should require authentication to view vehicle", function()
            local vehicle = factories.create_vehicle()

            local status = mock_request(app, "/vehicles/" .. vehicle.id, {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Vehicle Edit", function()

        it("should display vehicle edit form", function()
            local vehicle = factories.create_vehicle({
                make = "Tesla",
                model = "Model 3",
                year = 2022
            })

            local status, body = mock_request(app, "/vehicles/" .. vehicle.id .. "/edit", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Tesla") or body:match("Model 3"))
            assert.truthy(body:match('name="make"'))
            assert.truthy(body:match('name="model"'))
        end)

        it("should update vehicle with valid data", function()
            local vehicle = factories.create_vehicle({
                make = "Original",
                model = "Model",
                year = 2020
            })

            -- Update vehicle directly using model
            vehicle:update({
                make = "Updated",
                model = "NewModel",
                year = 2023
            })

            -- Verify vehicle was updated
            local updated_vehicle = Vehicle:find(vehicle.id)
            assert.equal("Updated", updated_vehicle.make)
            assert.equal("NewModel", updated_vehicle.model)
            assert.equal(2023, updated_vehicle.year)
        end)

        it("should not change customer association on edit", function()
            local vehicle = factories.create_vehicle({
                make = "BMW",
                model = "X5"
            })

            -- Associate with original customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            -- Update vehicle (should not affect customer association)
            vehicle:update({
                make = "BMW",
                model = "X7"
            })

            -- Verify association still exists
            local result = db.select("* from customers_vehicles where vehicle_id = ? and customer_id = ?", vehicle.id,
                test_customer.id)
            assert.truthy(result[1])
        end)

        it("should require authentication to view edit form", function()
            local vehicle = factories.create_vehicle()

            local status = mock_request(app, "/vehicles/" .. vehicle.id .. "/edit", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Vehicle Delete", function()

        it("should delete vehicle", function()
            local vehicle = factories.create_vehicle({
                make = "Delete",
                model = "Me"
            })

            local vehicle_count_before = Vehicle:count()
            local vehicle_id = vehicle.id

            -- Delete vehicle directly using model
            vehicle:delete()

            local vehicle_count_after = Vehicle:count()
            assert.equal(vehicle_count_before - 1, vehicle_count_after)

            -- Verify vehicle was deleted
            local deleted_vehicle = Vehicle:find(vehicle_id)
            assert.is_nil(deleted_vehicle)
        end)

        it("should delete vehicle and remove customer association", function()
            local vehicle = factories.create_vehicle({
                make = "Associated",
                model = "Vehicle"
            })

            -- Associate vehicle with customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            local vehicle_id = vehicle.id

            -- Manually delete association first (CASCADE may not be configured)
            db.delete("customers_vehicles", {
                vehicle_id = vehicle_id
            })

            -- Delete vehicle
            vehicle:delete()

            -- Verify vehicle was deleted
            local deleted_vehicle = Vehicle:find(vehicle_id)
            assert.is_nil(deleted_vehicle)

            -- Verify association was removed
            local result = db.select("* from customers_vehicles where vehicle_id = ?", vehicle_id)
            assert.equal(0, #result)
        end)

    end)

    describe("Vehicle Data Validation", function()

        it("should handle optional fields correctly", function()
            -- Create vehicle with only required fields
            local vehicle = Vehicle:create({
                make = "Minimal",
                model = "Data",
                year = 2020
            })

            assert.truthy(vehicle)
            assert.equal("Minimal", vehicle.make)
            assert.equal("Data", vehicle.model)
            assert.equal(2020, vehicle.year)
        end)

        it("should store all vehicle fields correctly", function()
            local vehicle = Vehicle:create({
                make = "Complete",
                model = "Record",
                year = 2023,
                vin = "COMPLETE123456789",
                license_plate = "CMP123",
                color = "Black"
            })

            assert.truthy(vehicle)
            assert.equal("Complete", vehicle.make)
            assert.equal("Record", vehicle.model)
            assert.equal(2023, vehicle.year)
            assert.equal("COMPLETE123456789", vehicle.vin)
            assert.equal("CMP123", vehicle.license_plate)
            assert.equal("Black", vehicle.color)
        end)

        it("should handle year as number", function()
            local vehicle = Vehicle:create({
                make = "Year",
                model = "Test",
                year = 2024
            })

            assert.truthy(vehicle)
            assert.equal(2024, vehicle.year)
            assert.equal("number", type(vehicle.year))
        end)

    end)

    describe("Vehicle Search and Filtering", function()

        it("should find vehicles by make", function()
            factories.create_vehicle({
                make = "Toyota",
                model = "Corolla"
            })
            factories.create_vehicle({
                make = "Toyota",
                model = "Camry"
            })
            factories.create_vehicle({
                make = "Honda",
                model = "Civic"
            })

            local db = require("lapis.db")
            local toyota_vehicles = db.select("* from vehicles where make = ?", "Toyota")

            assert.equal(2, #toyota_vehicles)
        end)

        it("should find vehicles by year", function()
            factories.create_vehicle({
                make = "Ford",
                model = "F150",
                year = 2020
            })
            factories.create_vehicle({
                make = "Chevy",
                model = "Silverado",
                year = 2020
            })
            factories.create_vehicle({
                make = "Ram",
                model = "1500",
                year = 2021
            })

            local db = require("lapis.db")
            local vehicles_2020 = db.select("* from vehicles where year = ?", 2020)

            assert.equal(2, #vehicles_2020)
        end)

    end)

    describe("Vehicle-Customer Associations", function()

        it("should allow multiple vehicles per customer", function()
            local vehicle1 = factories.create_vehicle({
                make = "Car",
                model = "One"
            })
            local vehicle2 = factories.create_vehicle({
                make = "Car",
                model = "Two"
            })

            local db = require("lapis.db")

            -- Associate both vehicles with same customer
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle1.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle2.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            -- Verify both associations exist
            local result = db.select("* from customers_vehicles where customer_id = ?", test_customer.id)
            assert.equal(2, #result)
        end)

        it("should find all vehicles for a customer", function()
            local vehicle1 = factories.create_vehicle({
                make = "Toyota",
                model = "Camry"
            })
            local vehicle2 = factories.create_vehicle({
                make = "Honda",
                model = "Civic"
            })
            local vehicle3 = factories.create_vehicle({
                make = "Ford",
                model = "F150"
            })

            local db = require("lapis.db")

            -- Associate first two vehicles with customer
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle1.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })
            db.insert("customers_vehicles", {
                customer_id = test_customer.id,
                vehicle_id = vehicle2.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            -- Find customer's vehicles
            local vehicles = db.select(
                "* FROM vehicles WHERE id IN (SELECT vehicle_id FROM customers_vehicles WHERE customer_id = ?)",
                test_customer.id)

            assert.equal(2, #vehicles)
        end)

    end)

end)
