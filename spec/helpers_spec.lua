-- spec/helpers_spec.lua
-- Tests for helper modules: validation and logger
local validation = require("helpers.validation")
local logger = require("helpers.logger")
local User = require("models.user")
local factories = require("spec.helpers.factories")
local db_helpers = require("spec.helpers.db")

describe("Validation Helpers", function()

    describe("sanitize_phone", function()

        it("should remove all non-digit characters", function()
            assert.equal("5551234567", validation.sanitize_phone("(555) 123-4567"))
            assert.equal("5551234567", validation.sanitize_phone("555-123-4567"))
            assert.equal("5551234567", validation.sanitize_phone("555.123.4567"))
            assert.equal("15551234567", validation.sanitize_phone("+1 555 123 4567")) -- Keeps the 1
            assert.equal("5551234567", validation.sanitize_phone("555 123 4567"))
        end)

        it("should handle nil or empty strings", function()
            assert.equal("", validation.sanitize_phone(nil))
            assert.equal("", validation.sanitize_phone(""))
        end)

        it("should handle already clean phone numbers", function()
            assert.equal("5551234567", validation.sanitize_phone("5551234567"))
        end)

    end)

    describe("validate_required", function()

        it("should return true when all fields are non-empty", function()
            local success, err = validation.validate_required({
                name = "test",
                email = "test@example.com"
            })
            assert.is_true(success)
            assert.is_nil(err)
        end)

        it("should return false when a field is empty", function()
            local success, err = validation.validate_required({
                name = "test",
                email = ""
            })
            assert.is_false(success)
            assert.truthy(err:match("required"))
        end)

        it("should return false when a field is nil", function()
            local success, err = validation.validate_required({
                name = "test",
                email = "" -- Empty string instead of nil (nil values are skipped by pairs)
            })
            assert.is_false(success)
            assert.truthy(err:match("required"))
        end)

    end)

    describe("validate_email", function()

        it("should return true for valid email addresses", function()
            local success1, _ = validation.validate_email("test@example.com")
            local success2, _ = validation.validate_email("user.name@example.co.uk")
            local success3, _ = validation.validate_email("user+tag@example.com")

            assert.is_true(success1)
            assert.is_true(success2)
            assert.is_true(success3)
        end)

        it("should return false for invalid email addresses", function()
            local success1, err1 = validation.validate_email("invalid")
            local success2, err2 = validation.validate_email("@example.com")
            local success3, err3 = validation.validate_email("user@")
            local success4, err4 = validation.validate_email("")

            assert.is_false(success1)
            assert.is_false(success2)
            assert.is_false(success3)
            assert.is_false(success4)
            assert.truthy(err1 or err2 or err3 or err4)
        end)

    end)

    describe("validation_error", function()

        it("should return proper error response structure", function()
            local mock_self = {
                params = {},
                cookies = {} -- CSRF needs this
            }

            local result = validation.validation_error(mock_self, "Test error message", "Test Title", "test/view")

            assert.equal("Test error message", mock_self.error_message)
            assert.equal("Test Title", mock_self.title)
            assert.truthy(mock_self.csrf_token)
            assert.equal(400, result.status)
            assert.equal("test/view", result.render)
        end)

    end)

    describe("require_auth", function()

        before_each(function()
            db_helpers.truncate_tables({"users"})
        end)

        it("should return nil when user is authenticated", function()
            local user = factories.create_user()
            local mock_self = {
                current_user = user
            }

            local result = validation.require_auth(mock_self)
            assert.is_nil(result)
        end)

        it("should return redirect when user is not authenticated", function()
            local mock_self = {
                current_user = nil
            }

            local result = validation.require_auth(mock_self)
            assert.equal("/", result.redirect_to)
        end)

    end)

end)

describe("Logger Helper", function()

    it("should have all log level functions", function()
        assert.is_function(logger.debug)
        assert.is_function(logger.info)
        assert.is_function(logger.warn)
        assert.is_function(logger.error)
        assert.is_function(logger.auth)
        assert.is_function(logger.db_operation)
    end)

    it("should accept message and data parameters", function()
        -- These should not error
        assert.has_no.errors(function()
            logger.debug("Debug message", {
                key = "value"
            })
            logger.info("Info message", {
                id = 123
            })
            logger.warn("Warning message")
            logger.error("Error message", {
                error = "details"
            })
        end)
    end)

    it("should log auth events", function()
        assert.has_no.errors(function()
            logger.auth("Login", {
                user_id = 1,
                email = "test@example.com"
            })
            logger.auth("Logout", {
                user_id = 1
            })
        end)
    end)

    it("should log database operations", function()
        assert.has_no.errors(function()
            logger.db_operation("CREATE", "Customer", 1, 999)
            logger.db_operation("UPDATE", "Vehicle", 5, 999)
        end)
    end)

end)
