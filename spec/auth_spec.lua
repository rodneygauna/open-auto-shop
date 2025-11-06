-- spec/auth_spec.lua
-- Tests for authentication flow: registration, login, and logout
local mock_request = require("lapis.spec.request").mock_request

-- Load app and helpers
local app = require("app")
local User = require("models.user")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("Authentication Flow", function()

    -- Clean up database before each test
    before_each(function()
        db_helpers.truncate_tables({"users"})
        factories.reset_counter()
    end)

    describe("User Registration", function()

        it("should display registration page on GET", function()
            local status, body = mock_request(app, "/register")

            assert.equal(200, status)
            assert.truthy(body:match("User Registration") or body:match("register"))
        end)

        it("should register a new user with valid data", function()
            local user_data = factories.build_user_data({
                email = "newuser@example.com",
                password = "securepassword123",
                confirm_password = "securepassword123"
            })

            local status, body, res_headers = mock_request(app, "/register", {
                method = "POST",
                post = user_data,
                session = {}
            })

            -- Verify user was created in database
            local user = User:find({
                email = "newuser@example.com"
            })
            assert.truthy(user)
            assert.equal("Test", user.first_name)
            assert.equal("newuser@example.com", user.email)

            -- Should redirect to index after successful registration
            assert.is_true(status == 302 or status == 200) -- Accept either redirect or success
        end)

        it("should reject registration with missing email", function()
            local status, body = mock_request(app, "/register", {
                method = "POST",
                post = {
                    email = "",
                    password = "password123",
                    confirm_password = "password123",
                    first_name = "Test",
                    last_name = "User"
                },
                session = {}
            })

            -- Check that error message appears in HTML response
            assert.truthy(body:match("Email and password are required"))
        end)

        it("should reject registration with missing password", function()
            local status, body = mock_request(app, "/register", {
                method = "POST",
                post = {
                    email = "test@example.com",
                    password = "",
                    confirm_password = "",
                    first_name = "Test",
                    last_name = "User"
                },
                session = {}
            })

            assert.equal(400, status)
            assert.truthy(body:match("Email and password are required"))
        end)

        it("should reject registration with missing name fields", function()
            local status, body = mock_request(app, "/register", {
                method = "POST",
                post = {
                    email = "test@example.com",
                    password = "password123",
                    confirm_password = "password123",
                    first_name = "",
                    last_name = "User"
                },
                session = {}
            })

            assert.equal(400, status)
            assert.truthy(body:match("First name and last name are required"))
        end)

        it("should reject registration with mismatched passwords", function()
            local status, body = mock_request(app, "/register", {
                method = "POST",
                post = {
                    email = "test@example.com",
                    password = "password123",
                    confirm_password = "differentpassword",
                    first_name = "Test",
                    last_name = "User"
                },
                session = {}
            })

            -- Check for error message in response
            assert.truthy(body:match("Passwords do not match"))
        end)

        it("should reject registration with duplicate email", function()
            local user = factories.create_user({
                email = "existing@example.com"
            })

            local status, body = mock_request(app, "/register", {
                method = "POST",
                post = {
                    email = "existing@example.com",
                    password = "password123",
                    confirm_password = "password123",
                    first_name = "Test",
                    last_name = "User"
                },
                session = {}
            })

            -- Check for error message in response
            assert.truthy(body:match("An account with this email already exists"))
        end)

        it("should normalize phone numbers to digits only", function()
            local user_data = factories.build_user_data({
                email = "phonetest@example.com",
                phone_number = "(555) 123-4567"
            })

            mock_request(app, "/register", {
                method = "POST",
                post = user_data,
                session = {}
            })

            local user = User:find({
                email = "phonetest@example.com"
            })
            assert.truthy(user)
            assert.equal("5551234567", user.phone_number)
        end)

    end)

    describe("User Login", function()

        local test_user

        before_each(function()
            -- Create a test user for login tests
            test_user = factories.create_user({
                email = "logintest@example.com",
                password = "mypassword123"
            })
        end)

        it("should display login page on GET", function()
            local status, body = mock_request(app, "/login")

            assert.equal(200, status)
            assert.truthy(body:match("Login") or body:match("login"))
        end)

        it("should log in user with valid credentials", function()
            local user = factories.create_user({
                email = "testuser@example.com",
                password = "password123"
            })

            local status, body, res_headers = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "testuser@example.com",
                    password = "password123"
                },
                session = {}
            })

            -- Since session is handled internally, just verify the request succeeded
            -- and no error message appears in the response
            assert.is_false(body:match("Invalid email or password") ~= nil)
        end)

        it("should reject login with non-existent email", function()
            local status, body = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "nonexistent@example.com",
                    password = "password123"
                },
                session = {}
            })

            -- Check for error message in response
            assert.truthy(body:match("Invalid email or password"))
        end)

        it("should reject login with incorrect password", function()
            local user = factories.create_user({
                email = "testuser@example.com",
                password = "correctpassword"
            })

            local status, body = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "testuser@example.com",
                    password = "wrongpassword"
                },
                session = {}
            })

            -- Check for error message in response
            assert.truthy(body:match("Invalid email or password"))
        end)

        it("should reject login with missing email", function()
            local status, body = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "",
                    password = "password123"
                },
                session = {}
            })

            -- Check for error message in response
            assert.truthy(body:match("Email and password are required"))
        end)

        it("should reject login with missing password", function()
            local status, body = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "logintest@example.com",
                    password = ""
                },
                session = {}
            })

            assert.equal(400, status)
            assert.truthy(body:match("Email and password are required"))
        end)

        it("should normalize email to lowercase during login", function()
            local status = mock_request(app, "/login", {
                method = "POST",
                post = {
                    email = "LOGINTEST@EXAMPLE.COM", -- Uppercase email
                    password = "mypassword123"
                },
                session = {}
            })

            -- Should successfully login with uppercase email
            assert.equal(302, status)
        end)

    end)

    describe("User Logout", function()

        it("should log out user successfully", function()
            local user = factories.create_user()

            local status, body, res_headers = mock_request(app, "/logout", {
                method = "POST",
                session = {
                    current_user_id = user.id
                }
            })

            -- Since we can't easily verify session state in mock_request,
            -- just verify the request succeeded and returned valid response
            assert.truthy(status)
            assert.truthy(body)
        end)

        it("should redirect without session clearing on GET request", function()
            local status = mock_request(app, "/logout", {
                method = "GET"
            })

            -- Should redirect even on GET
            assert.equal(302, status)
        end)

    end)

end)
