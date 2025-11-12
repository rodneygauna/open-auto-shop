-- spec/csrf_spec.lua
-- Tests for CSRF protection across all forms
local mock_request = require("lapis.spec.request").mock_request
local csrf = require("lapis.csrf")

-- Load app and helpers
local app = require("app")
local User = require("models.user")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("CSRF Protection", function()

    local test_user
    local session

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
    end)

    describe("CSRF Token Generation", function()

        it("should generate different tokens for different sessions", function()
            local session1 = {
                id = "session1"
            }
            local session2 = {
                id = "session2"
            }

            local mock_self1 = {
                session = session1,
                cookies = {}
            }
            local mock_self2 = {
                session = session2,
                cookies = {}
            }

            local token1 = csrf.generate_token(mock_self1)
            local token2 = csrf.generate_token(mock_self2)

            -- Tokens should be different for different sessions
            assert.is_not_equal(token1, token2)
        end)

        it("should generate tokens that are not empty", function()
            local mock_self = {
                session = session,
                cookies = {}
            }
            local token = csrf.generate_token(mock_self)

            assert.truthy(token)
            assert.is_true(#token > 0)
        end)

        it("should generate consistent tokens for same session", function()
            local mock_self = {
                session = session,
                cookies = {}
            }

            local token1 = csrf.generate_token(mock_self)
            local token2 = csrf.generate_token(mock_self)

            -- Should be same token for same session
            assert.equal(token1, token2)
        end)

    end)

    describe("CSRF Token in Forms", function()

        it("should include CSRF token in customer create form", function()
            local status, body = mock_request(app, "/customers/create", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in customer edit form", function()
            local customer = factories.create_customer()

            local status, body = mock_request(app, "/customers/" .. customer.id .. "/edit", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in vehicle create form", function()
            local status, body = mock_request(app, "/vehicles/create", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in vehicle edit form", function()
            local vehicle = factories.create_vehicle()

            local status, body = mock_request(app, "/vehicles/" .. vehicle.id .. "/edit", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in login form", function()
            local status, body = mock_request(app, "/login", {
                method = "GET"
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in registration form", function()
            local status, body = mock_request(app, "/register", {
                method = "GET"
            })

            assert.equal(200, status)
            assert.truthy(body:match('name="csrf_token"'))
        end)

        it("should include CSRF token in logout button", function()
            local status, body = mock_request(app, "/", {
                method = "GET",
                session = session
            })

            assert.equal(200, status)
            -- Check for CSRF token in the logout form in the navigation
            assert.truthy(body:match('action="/logout"') and body:match('csrf_token'))
        end)

    end)

end)

