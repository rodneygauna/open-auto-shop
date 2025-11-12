-- spec/models_spec.lua
-- Tests for model relations and helper methods
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local CustomersVehicles = require("models.customers_vehicles")
local db_helpers = require("spec.helpers.db")

describe("Model Relations", function()

    before_each(function()
        db_helpers.truncate_tables({"customers_vehicles", "vehicles", "customers"})
    end)

    describe("Customer Model", function()

        it("should create a customer", function()
            local customer = Customer:create({
                first_name = "John",
                last_name = "Doe",
                email = "john@example.com",
                phone_number = "5551234567"
            })

            assert.truthy(customer)
            assert.equal("John", customer.first_name)
            assert.equal("Doe", customer.last_name)
        end)

        it("should get vehicles for a customer using raw SQL", function()
            -- Create customer
            local customer = Customer:create({
                first_name = "Jane",
                last_name = "Smith",
                email = "jane@example.com",
                phone_number = "5559876543"
            })

            -- Create vehicles
            local vehicle1 = Vehicle:create({
                make = "Toyota",
                model = "Camry",
                year = 2020,
                vin = "1234567890ABCDEFG"
            })

            local vehicle2 = Vehicle:create({
                make = "Honda",
                model = "Civic",
                year = 2019,
                vin = "ABCDEFG1234567890"
            })

            -- Associate vehicles with customer
            CustomersVehicles:create({
                customer_id = customer.id,
                vehicle_id = vehicle1.id
            })

            CustomersVehicles:create({
                customer_id = customer.id,
                vehicle_id = vehicle2.id
            })

            -- Get vehicles using SQL query (similar to helper method)
            local db = require("lapis.db")
            local vehicles = db.query([[
                SELECT v.* FROM vehicles v
                INNER JOIN customers_vehicles cv ON v.id = cv.vehicle_id
                WHERE cv.customer_id = ?
            ]], customer.id)

            assert.equal(2, #vehicles)

            -- Verify vehicles are returned
            local makes = {}
            for _, v in ipairs(vehicles) do
                makes[v.make] = true
            end
            assert.truthy(makes["Toyota"])
            assert.truthy(makes["Honda"])
        end)

        it("should return empty list when customer has no vehicles", function()
            local customer = Customer:create({
                first_name = "Bob",
                last_name = "Jones",
                email = "bob@example.com",
                phone_number = "5555555555"
            })

            local db = require("lapis.db")
            local vehicles = db.query([[
                SELECT v.* FROM vehicles v
                INNER JOIN customers_vehicles cv ON v.id = cv.vehicle_id
                WHERE cv.customer_id = ?
            ]], customer.id)

            assert.equal(0, #vehicles)
        end)

    end)

    describe("Vehicle Model", function()

        it("should create a vehicle", function()
            local vehicle = Vehicle:create({
                make = "Ford",
                model = "F-150",
                year = 2021,
                vin = "FORD1234567890ABC",
                license_plate = "ABC123",
                color = "Blue"
            })

            assert.truthy(vehicle)
            assert.equal("Ford", vehicle.make)
            assert.equal("F-150", vehicle.model)
            assert.equal(2021, vehicle.year)
        end)

        it("should find customer for a vehicle using association", function()
            -- Create customer
            local customer = Customer:create({
                first_name = "Alice",
                last_name = "Johnson",
                email = "alice@example.com",
                phone_number = "5551112222"
            })

            -- Create vehicle
            local vehicle = Vehicle:create({
                make = "Tesla",
                model = "Model 3",
                year = 2022,
                vin = "TESLA1234567890"
            })

            -- Associate vehicle with customer
            CustomersVehicles:create({
                customer_id = customer.id,
                vehicle_id = vehicle.id
            })

            -- Find customer via CustomersVehicles association
            local cv = CustomersVehicles:find({
                vehicle_id = vehicle.id
            })
            assert.truthy(cv)

            local owner = Customer:find(cv.customer_id)
            assert.truthy(owner)
            assert.equal(customer.id, owner.id)
            assert.equal("Alice", owner.first_name)
            assert.equal("Johnson", owner.last_name)
        end)

        it("should return nil when vehicle has no customer", function()
            local vehicle = Vehicle:create({
                make = "BMW",
                model = "X5",
                year = 2023,
                vin = "BMW1234567890"
            })

            -- Try to find customer association
            local cv = CustomersVehicles:find({
                vehicle_id = vehicle.id
            })
            assert.is_nil(cv)
        end)

    end)

end)
