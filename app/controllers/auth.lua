-- app/controllers/auth.lua
local lapis = require("lapis")
local bcrypt = require("bcrypt")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local User = require("models.user")
local config = require("lapis.config").get()
local validation = require("helpers.validation")
local logger = require("helpers.logger")

-- Create an authentication controller
local app = lapis.Application()

-- Registration route
app:match("register", "/register", respond_to({
    GET = function(self)
        self.csrf_token = csrf.generate_token(self)
        self.title = "User Registration"
        self.error_message = self.params.error_message
        return {
            render = "auth/register"
        }
    end,

    POST = capture_errors(function(self)
        if config._name ~= "test" then
            csrf.assert_token(self)
        end

        local email = tostring(self.params.email or ""):lower()
        local password = self.params.password or ""
        local confirm_password = self.params.confirm_password or ""
        local first_name = tostring(self.params.first_name or "")
        local last_name = tostring(self.params.last_name or "")
        local phone_number = validation.sanitize_phone(self.params.phone)
        local title = tostring(self.params.title or "")
        local is_admin

        -- Validate required fields
        if email == "" or password == "" then
            return validation.validation_error(self, "Email and password are required", "User Registration",
                "auth/register")
        end

        -- Validate name fields
        if first_name == "" or last_name == "" then
            return validation.validation_error(self, "First name and last name are required", "User Registration",
                "auth/register")
        end

        -- Check password confirmation
        if password ~= confirm_password then
            return validation.validation_error(self, "Passwords do not match", "User Registration", "auth/register")
        end

        -- Check if user already exists
        if User:find({
            email = email
        }) then
            return validation.validation_error(self, "An account with this email already exists", "User Registration",
                "auth/register")
        end

        -- Check if this is the first user and make them an admin
        local user_count = User:count()
        if user_count == 0 then
            is_admin = true
        else
            is_admin = false
        end

        -- Create new user with error handling
        local hash = bcrypt.digest(password, config.bcrypt_rounds)
        local success, user = pcall(function()
            return User:create({
                email = email,
                password_hash = hash,
                first_name = first_name,
                last_name = last_name,
                phone_number = phone_number,
                title = title,
                is_admin = is_admin
            })
        end)

        if not success then
            logger.error("User registration failed", {
                email = email
            })
            return validation.validation_error(self, "Failed to create user account", "User Registration",
                "auth/register")
        end

        -- Log the registration
        logger.auth("User registered", {
            user_id = user.id,
            email = user.email,
            is_admin = user.is_admin
        })

        -- Log user in
        self.session.current_user_id = user.id
        return {
            redirect_to = self:url_for("index")
        }
    end)
}))

-- Login route
app:match("login", "/login", respond_to({
    GET = function(self)
        self.csrf_token = csrf.generate_token(self)
        self.title = "Login"
        self.error_message = self.params.error_message
        return {
            render = "auth/login"
        }
    end,

    POST = capture_errors(function(self)
        -- Skip CSRF in test environment
        if config._name ~= "test" then
            csrf.assert_token(self)
        end

        local email = tostring(self.params.email or ""):lower()
        local password = self.params.password or ""

        -- Validate required fields
        if email == "" or password == "" then
            return validation.validation_error(self, "Email and password are required", "Login", "auth/login")
        end

        -- Find user and verify password
        local user = User:find({
            email = email
        })
        if not (user and bcrypt.verify(password, user.password_hash)) then
            logger.warn("Failed login attempt", {
                email = email
            })
            return validation.validation_error(self, "Invalid email or password", "Login", "auth/login")
        end

        -- Log successful login
        logger.auth("User logged in", {
            user_id = user.id,
            email = user.email
        })

        -- Log user in
        self.session.current_user_id = user.id
        return {
            redirect_to = self:url_for("index")
        }
    end)
}))

-- Logout route
app:match("logout", "/logout", function(self)
    if self.req.method == "POST" then
        -- Skip CSRF in test environment
        if config._name ~= "test" then
            csrf.assert_token(self)
        end

        -- Log logout before clearing session
        if self.current_user then
            logger.auth("User logged out", {
                user_id = self.current_user.id,
                email = self.current_user.email
            })
        end

        self.session.current_user_id = nil
    end
    return {
        redirect_to = self:url_for("index")
    }
end)

return app
