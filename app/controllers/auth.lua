-- app/controllers/auth.lua
local lapis = require("lapis")
local bcrypt = require("bcrypt")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local User = require("models.user")

-- Create an authentication controller
local app = lapis.Application()

-- Registration route
app:match("register", "/register", respond_to({
    GET = function(self)
        self.csrf_token = csrf.generate_token(self)
        self.title = "User Registration"
        self.error_message = self.params.error_message
        return {
            render = "register"
        }
    end,

    POST = capture_errors(function(self)
        csrf.assert_token(self)

        local email = tostring(self.params.email or ""):lower()
        local password = self.params.password or ""
        local confirm_password = self.params.confirm_password or ""
        local first_name = tostring(self.params.first_name or "")
        local last_name = tostring(self.params.last_name or "")
        local phone_number = tostring(self.params.phone or "")
        local title = tostring(self.params.title or "")

        -- Validate required fields
        if email == "" or password == "" then
            self.error_message = "Email and password are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "User Registration"
            return {
                status = 400,
                render = "register"
            }
        end

        -- Validate name fields
        if first_name == "" or last_name == "" then
            self.error_message = "First name and last name are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "User Registration"
            return {
                status = 400,
                render = "register"
            }
        end

        -- Strip the phone number to digits only
        phone_number = phone_number:gsub("%D", "")

        -- Check password confirmation
        if password ~= confirm_password then
            self.error_message = "Passwords do not match"
            self.csrf_token = csrf.generate_token(self)
            self.title = "User Registration"
            return {
                status = 400,
                render = "register"
            }
        end

        -- Check if user already exists
        if User:find({
            email = email
        }) then
            self.error_message = "An account with this email already exists"
            self.csrf_token = csrf.generate_token(self)
            self.title = "User Registration"
            return {
                status = 400,
                render = "register"
            }
        end

        -- Create new user
        local hash = bcrypt.digest(password, 12)
        local user = User:create({
            email = email,
            password_hash = hash,
            first_name = first_name,
            last_name = last_name,
            phone_number = phone_number,
            title = title
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
            render = "login"
        }
    end,

    POST = capture_errors(function(self)
        csrf.assert_token(self)

        local email = tostring(self.params.email or ""):lower()
        local password = self.params.password or ""

        -- Validate required fields
        if email == "" or password == "" then
            self.error_message = "Email and password are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Login"
            return {
                status = 400,
                render = "login"
            }
        end

        -- Find user and verify password
        local user = User:find({
            email = email
        })
        if not (user and bcrypt.verify(password, user.password_hash)) then
            self.error_message = "Invalid email or password"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Login"
            return {
                status = 400,
                render = "login"
            }
        end

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
        csrf.assert_token(self)
        self.session.current_user_id = nil
    end
    return {
        redirect_to = self:url_for("index")
    }
end)

return app
