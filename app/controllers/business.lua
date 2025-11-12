-- app/controllers/business.lua
local lapis = require("lapis")
local config = require("lapis.config").get()
local bcrypt = require("bcrypt")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Business = require("models.business")
local validation = require("helpers.validation")

-- Create a business controller
local app = lapis.Application()

-- Business create route
app:match("create_business", "/business/create", respond_to({
    GET = function(self)
        local helpers = require("helpers.view_helpers")
        local data = require("helpers.data_dictionaries")
        self.helpers = helpers
        self.data = data
        self.csrf_token = csrf.generate_token(self)
        self.title = "Create Business"
        self.error_message = self.params.error_message
        return {
            render = "business/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        csrf.assert_token(self)

        local name = tostring(self.params.name or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")
        local phone_number = tostring(self.params.phone_number or "")
        local email = tostring(self.params.email or "")
        local website = tostring(self.params.website or "")

        -- Validate required fields
        if name == "" then
            return
                validation.validation_error(self, "Business name is required", "Create Business", "business/add-edit")
        end

        -- Strip the phone number to digits only
        phone_number = validation.sanitize_phone(phone_number)

        -- Create the business with error handling
        local success, business = pcall(function()
            return Business:create({
                name = name,
                address1 = address1,
                address2 = address2,
                city = city,
                state = state,
                zip_code = zip_code,
                phone_number = phone_number,
                email = email,
                website = website
            })
        end)

        if not success then
            return
                validation.validation_error(self, "Failed to create business", "Create Business", "business/add-edit")
        end

        -- Redirect to business list or detail page
        return {
            redirect_to = "/business/" .. business.id
        }
    end)
}))

-- Business edit route
app:match("edit_business", "/business/:id/edit", respond_to({
    GET = function(self)
        local business = Business:find(self.params.id)
        if not business then
            self.title = "404 - Not Found"
            self.error_message = "Business not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        local helpers = require("helpers.view_helpers")
        local data = require("helpers.data_dictionaries")
        self.helpers = helpers
        self.data = data
        self.business = business
        self.csrf_token = csrf.generate_token(self)
        self.title = "Edit Business"
        return {
            render = "business/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        csrf.assert_token(self)

        local business = Business:find(self.params.id)
        if not business then
            self.title = "404 - Not Found"
            self.error_message = "Business not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        local name = tostring(self.params.name or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")
        local phone_number = tostring(self.params.phone_number or "")
        local email = tostring(self.params.email or "")
        local website = tostring(self.params.website or "")

        -- Validate required fields
        if name == "" then
            self.business = business
            return validation.validation_error(self, "Business name is required", "Edit Business", "business/add-edit")
        end

        -- Strip the phone number to digits only
        phone_number = validation.sanitize_phone(phone_number)

        -- Update the business with error handling
        local success, err = pcall(function()
            business:update({
                name = name,
                address1 = address1,
                address2 = address2,
                city = city,
                state = state,
                zip_code = zip_code,
                phone_number = phone_number,
                email = email,
                website = website
            })
        end)

        if not success then
            self.business = business
            return validation.validation_error(self, "Failed to update business", "Edit Business", "business/add-edit")
        end

        -- Redirect to business detail page
        return {
            redirect_to = "/business/" .. business.id
        }
    end)
}))

-- Business detail route
app:match("business_detail", "/business/:id", respond_to({
    GET = function(self)
        local business = Business:find(self.params.id)
        if not business then
            self.title = "404 - Not Found"
            self.error_message = "Business not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        local helpers = require("helpers.view_helpers")
        local data = require("helpers.data_dictionaries")
        self.helpers = helpers
        self.data = data
        self.business = business
        self.title = business.name
        return {
            render = "business/show"
        }
    end
}))

return app
