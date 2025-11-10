-- app/controllers/business.lua
local lapis = require("lapis")
local bcrypt = require("bcrypt")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Business = require("models.business")

-- Create a business controller
local app = lapis.Application()

-- Business create route
app:match("create_business", "/business/create", respond_to({
    GET = function(self)
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
            self.error_message = "Business name is required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Create Business"
            return {
                status = 400,
                render = "business/add-edit"
            }
        end

        -- Strip the phone number to digits only
        phone_number = phone_number:gsub("%D", "")

        -- Create the business
        local business = Business:create({
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
            return {
                status = 404,
                render = "404"
            }
        end

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
            return {
                status = 404,
                render = "404"
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
            self.error_message = "Business name is required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Edit Business"
            self.business = business
            return {
                status = 400,
                render = "business/add-edit"
            }
        end

        -- Strip the phone number to digits only
        phone_number = phone_number:gsub("%D", "")

        -- Update the business
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
            return {
                status = 404,
                render = "404"
            }
        end

        self.business = business
        self.title = business.name
        return {
            render = "business/show"
        }
    end
}))

return app
