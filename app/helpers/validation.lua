-- app/helpers/validation.lua
-- Validation and sanitization helpers
local M = {}

-- Sanitize phone number (strip all non-digit characters)
function M.sanitize_phone(phone)
    if not phone then
        return ""
    end
    return tostring(phone):gsub("%D", "")
end

-- Create a validation error response (reduces duplication in controllers)
function M.validation_error(self, error_message, title, render_view, csrf_token)
    self.error_message = error_message
    self.title = title or "Error"
    if csrf_token ~= false then
        local csrf = require("lapis.csrf")
        self.csrf_token = csrf.generate_token(self)
    end
    return {
        status = 400,
        render = render_view
    }
end

-- Check if user is authenticated, redirect if not
function M.require_auth(self, redirect_to)
    if not self.current_user then
        return {
            redirect_to = redirect_to or "/"
        }
    end
    return nil
end

-- Validate required fields are not empty
function M.validate_required(fields)
    for field_name, value in pairs(fields) do
        if not value or value == "" then
            return false, field_name .. " is required"
        end
    end
    return true, nil
end

-- Validate email format (basic)
function M.validate_email(email)
    if not email or email == "" then
        return false, "Email is required"
    end
    if not email:match("^[%w%._%+-]+@[%w%._%+-]+%.%w+$") then
        return false, "Invalid email format"
    end
    return true, nil
end

return M
