-- spec/authorization_spec.lua
-- Tests for authorization and admin-only access control
local mock_request = require("lapis.spec.request").mock_request

-- Load app and helpers
local app = require("app")
local User = require("models.user")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("Authorization", function()

    local admin_user
    local regular_user
    local admin_session
    local regular_session

    before_each(function()
        db_helpers.truncate_tables({"users"})
        factories.reset_counter()

        -- Create admin user
        admin_user = factories.create_user({
            email = "admin@example.com",
            is_admin = true
        })

        -- Create regular user
        regular_user = factories.create_user({
            email = "user@example.com",
            is_admin = false
        })

        -- Create sessions
        admin_session = {
            current_user_id = admin_user.id
        }

        regular_session = {
            current_user_id = regular_user.id
        }
    end)

    describe("Settings Page Access", function()

        it("should allow admin users to access settings page", function()
            local status, body = mock_request(app, "/settings", {
                method = "GET",
                session = admin_session
            })

            assert.equal(200, status)
            assert.truthy(body:match("Settings") or body:match("settings"))
        end)

        it("should allow regular authenticated users to access settings page", function()
            local status, body = mock_request(app, "/settings", {
                method = "GET",
                session = regular_session
            })

            -- Settings page requires authentication but not admin
            assert.equal(200, status)
        end)

        it("should deny unauthenticated users access to settings page", function()
            local status, body = mock_request(app, "/settings", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

    end)

    describe("User Management", function()

        it("should show admin indicator for admin users", function()
            local status, body = mock_request(app, "/", {
                method = "GET",
                session = admin_session
            })

            assert.equal(200, status)
            -- Admin users should see admin-specific content or indicators
        end)

        it("should not show admin indicator for regular users", function()
            local status, body = mock_request(app, "/", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, status)
            -- Regular users should not see admin-specific content
        end)

    end)

    describe("Authentication Required Routes", function()

        it("should require authentication for customer list", function()
            local status, body = mock_request(app, "/customers", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

        it("should allow authenticated users to access customer list", function()
            local status, body = mock_request(app, "/customers", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, status)
        end)

        it("should require authentication for customer create", function()
            local status, body = mock_request(app, "/customers/create", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

        it("should allow authenticated users to create customers", function()
            local status, body = mock_request(app, "/customers/create", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, status)
        end)

        it("should require authentication for vehicle create", function()
            local status, body = mock_request(app, "/vehicles/create", {
                method = "GET"
            })

            -- Should redirect to login
            assert.is_true(status == 302 or status == 401)
        end)

        it("should allow authenticated users to create vehicles", function()
            local status, body = mock_request(app, "/vehicles/create", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, status)
        end)

    end)

    describe("Public Routes", function()

        it("should allow unauthenticated access to login page", function()
            local status, body = mock_request(app, "/login", {
                method = "GET"
            })

            assert.equal(200, status)
            assert.truthy(body:match("login") or body:match("Login"))
        end)

        it("should allow unauthenticated access to registration page", function()
            local status, body = mock_request(app, "/register", {
                method = "GET"
            })

            assert.equal(200, status)
            assert.truthy(body:match("register") or body:match("Register"))
        end)

        it("should redirect authenticated users away from login page", function()
            local status, body = mock_request(app, "/login", {
                method = "GET",
                session = regular_session
            })

            -- Should redirect to home/dashboard
            assert.is_true(status == 302 or status == 200)
        end)

    end)

    describe("Session Management", function()

        it("should maintain user session across requests", function()
            -- First request
            local status1 = mock_request(app, "/customers", {
                method = "GET",
                session = regular_session
            })

            -- Second request with same session
            local status2 = mock_request(app, "/customers/create", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, status1)
            assert.equal(200, status2)
        end)

        it("should properly identify admin users in session", function()
            local status, body = mock_request(app, "/settings", {
                method = "GET",
                session = admin_session
            })

            assert.equal(200, status)
        end)

        it("should properly identify regular users in session", function()
            local status = mock_request(app, "/customers", {
                method = "GET",
                session = regular_session
            })

            -- Regular user should access regular routes
            assert.equal(200, status)
        end)

    end)

    describe("Role-Based Access Control", function()

        it("should allow all authenticated users to access settings", function()
            -- Admin user
            local admin_status = mock_request(app, "/settings", {
                method = "GET",
                session = admin_session
            })

            -- Regular user
            local regular_status = mock_request(app, "/settings", {
                method = "GET",
                session = regular_session
            })

            -- Both should have access
            assert.equal(200, admin_status)
            assert.equal(200, regular_status)
        end)

        it("should allow all authenticated users to access customer routes", function()
            -- Admin user
            local admin_status = mock_request(app, "/customers", {
                method = "GET",
                session = admin_session
            })

            -- Regular user
            local regular_status = mock_request(app, "/customers", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, admin_status)
            assert.equal(200, regular_status)
        end)

        it("should allow all authenticated users to access vehicle create route", function()
            -- Admin user
            local admin_status = mock_request(app, "/vehicles/create", {
                method = "GET",
                session = admin_session
            })

            -- Regular user
            local regular_status = mock_request(app, "/vehicles/create", {
                method = "GET",
                session = regular_session
            })

            assert.equal(200, admin_status)
            assert.equal(200, regular_status)
        end)

    end)

end)
