-- spec/customers_crud_spec.lua
-- Tests for Customer CRUD operations
local mock_request = require("lapis.spec.request").mock_request
local csrf = require("lapis.csrf")

-- Load app and helpers
local app = require("app")
local User = require("models.user")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("Customer CRUD Operations", function()

    local test_user
    local session
    local csrf_token

    before_each(function()
        db_helpers.truncate_tables({"users", "customers", "vehicles", "customers_vehicles"})
        factories.reset_counter()

        -- Create test user
        test_user = factories.create_user({
            email = "test@example.com",
            is_admin = true
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

    describe("Customer List", function()

        it("should display empty customer list when no customers exist", function()
            local status, body = mock_request(app, "/customers", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Customers") or body:match("customers"))
        end)

        it("should display customer list with existing customers", function()
            -- Create test customers
            factories.create_customer({
                first_name = "John",
                last_name = "Doe",
                email = "john@example.com"
            })
            factories.create_customer({
                first_name = "Jane",
                last_name = "Smith",
                email = "jane@example.com"
            })

            local status, body = mock_request(app, "/customers", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("John") or body:match("Doe"))
            assert.truthy(body:match("Jane") or body:match("Smith"))
        end)

        it("should handle pagination for customer list", function()
            local status, body = mock_request(app, "/customers?page=1", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
        end)

        it("should require authentication to view customer list", function()
            local status = mock_request(app, "/customers", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Customer Create", function()

        it("should display customer create form", function()
            local status, body = mock_request(app, "/customers/create", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Customer") or body:match("customer"))
            assert.truthy(body:match('name="first_name"'))
            assert.truthy(body:match('name="last_name"'))
        end)

        it("should create a customer with valid data directly in database", function()
            local customer_count_before = Customer:count()

            -- Create customer directly using model
            local customer = Customer:create({
                first_name = "Test",
                last_name = "Customer",
                email = "testcustomer@example.com",
                phone_number = "5551234567",
                address1 = "123 Test St",
                city = "Test City",
                state = "TS",
                zip_code = "12345"
            })

            assert.truthy(customer)
            assert.equal("Test", customer.first_name)
            assert.equal("Customer", customer.last_name)

            local customer_count_after = Customer:count()
            assert.equal(customer_count_before + 1, customer_count_after)
        end)

        it("should require authentication to view create form", function()
            local status = mock_request(app, "/customers/create", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Customer View", function()

        it("should display customer details", function()
            local customer = factories.create_customer({
                first_name = "View",
                last_name = "Test",
                email = "view@example.com",
                phone_number = "5559876543"
            })

            local status, body = mock_request(app, "/customers/" .. customer.id, {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("View") and body:match("Test"))
            assert.truthy(body:match("view@example.com"))
        end)

        it("should display customer with associated vehicles", function()
            local customer = factories.create_customer({
                first_name = "Vehicle",
                last_name = "Owner"
            })

            local vehicle = factories.create_vehicle({
                make = "Toyota",
                model = "Camry",
                year = 2020
            })

            -- Associate vehicle with customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            local status, body = mock_request(app, "/customers/" .. customer.id, {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Vehicle") and body:match("Owner"))
            assert.truthy(body:match("Toyota") or body:match("Camry"))
        end)

        it("should require authentication to view customer", function()
            local customer = factories.create_customer()

            local status = mock_request(app, "/customers/" .. customer.id, {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Customer Edit", function()

        it("should display customer edit form", function()
            local customer = factories.create_customer({
                first_name = "Edit",
                last_name = "Me",
                email = "edit@example.com"
            })

            local status, body = mock_request(app, "/customers/" .. customer.id .. "/edit", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Edit") and body:match("Me"))
            assert.truthy(body:match('name="first_name"'))
            assert.truthy(body:match('value="Edit"') or body:match(">Edit<"))
        end)

        it("should update customer data directly in database", function()
            local customer = factories.create_customer({
                first_name = "Original",
                last_name = "Name",
                email = "original@example.com"
            })

            -- Update customer directly using model
            customer:update({
                first_name = "Updated",
                last_name = "NewName",
                email = "updated@example.com"
            })

            -- Verify customer was updated
            local updated_customer = Customer:find(customer.id)
            assert.equal("Updated", updated_customer.first_name)
            assert.equal("NewName", updated_customer.last_name)
            assert.equal("updated@example.com", updated_customer.email)
        end)

        it("should require authentication to view edit form", function()
            local customer = factories.create_customer()

            local status = mock_request(app, "/customers/" .. customer.id .. "/edit", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("Customer Delete", function()

        it("should delete customer without vehicles", function()
            local customer = factories.create_customer({
                first_name = "Delete",
                last_name = "Me"
            })

            local customer_count_before = Customer:count()
            local customer_id = customer.id

            -- Delete customer directly using model
            customer:delete()

            local customer_count_after = Customer:count()
            assert.equal(customer_count_before - 1, customer_count_after)

            -- Verify customer was deleted
            local deleted_customer = Customer:find(customer_id)
            assert.is_nil(deleted_customer)
        end)

        it("should handle deletion of customer with vehicles", function()
            local customer = factories.create_customer({
                first_name = "Has",
                last_name = "Vehicle"
            })

            local vehicle = factories.create_vehicle({
                make = "Ford",
                model = "F150"
            })

            -- Associate vehicle with customer
            local db = require("lapis.db")
            db.insert("customers_vehicles", {
                customer_id = customer.id,
                vehicle_id = vehicle.id,
                created_at = db.format_date(),
                updated_at = db.format_date()
            })

            local customer_count_before = Customer:count()
            local customer_id = customer.id
            local vehicle_id = vehicle.id

            -- Delete customer (should cascade delete association)
            customer:delete()

            local customer_count_after = Customer:count()
            assert.equal(customer_count_before - 1, customer_count_after)

            -- Verify customer was deleted
            local deleted_customer = Customer:find(customer_id)
            assert.is_nil(deleted_customer)

            -- Verify vehicle still exists (not cascade deleted)
            local existing_vehicle = Vehicle:find(vehicle_id)
            assert.truthy(existing_vehicle)
        end)

    end)

    describe("Customer Data Validation", function()

        it("should handle optional fields correctly", function()
            -- Create customer with only required fields
            local customer = Customer:create({
                first_name = "Minimal",
                last_name = "Data"
            })

            assert.truthy(customer)
            assert.equal("Minimal", customer.first_name)
            assert.equal("Data", customer.last_name)
        end)

        it("should store all customer fields correctly", function()
            local customer = Customer:create({
                first_name = "Complete",
                last_name = "Record",
                middle_name = "Middle",
                suffix_name = "Jr.",
                email = "complete@example.com",
                phone_number = "5551234567",
                address1 = "123 Main St",
                address2 = "Apt 4",
                city = "Springfield",
                state = "IL",
                zip_code = "62701"
            })

            assert.truthy(customer)
            assert.equal("Complete", customer.first_name)
            assert.equal("Record", customer.last_name)
            assert.equal("Middle", customer.middle_name)
            assert.equal("Jr.", customer.suffix_name)
            assert.equal("complete@example.com", customer.email)
            assert.equal("5551234567", customer.phone_number)
            assert.equal("123 Main St", customer.address1)
            assert.equal("Apt 4", customer.address2)
            assert.equal("Springfield", customer.city)
            assert.equal("IL", customer.state)
            assert.equal("62701", customer.zip_code)
        end)

    end)

end)
