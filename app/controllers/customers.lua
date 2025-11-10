-- app/controllers/customers.lua
local lapis = require("lapis")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Customer = require("models.customer")
local User = require("models.user")

-- Create a customers controller
local app = lapis.Application()

-- Customers list route
app:match("customers", "/customers", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        -- Fetch all customers
        local customers = Customer:select()
        self.customers = customers
        self.title = "Customers"
        return {
            render = "customers-index"
        }
    end
}))

-- Customer create route
app:match("create_customer", "/customers/create", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        self.title = "Create Customer"
        self.error_message = self.params.error_message
        return {
            render = "customers-add-edit"
        }
    end,
    POST = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        local first_name = self.params.first_name
        local middle_name = self.params.middle_name
        local last_name = self.params.last_name
        local suffix_name = self.params.suffix_name
        local phone_number = self.params.phone_number
        local email = self.params.email
        local address1 = self.params.address1
        local address2 = self.params.address2
        local city = self.params.city
        local state = self.params.state
        local zip_code = self.params.zip_code

        if not first_name or not last_name then
            return {
                redirect_to = "/customers/create?error_message=All+fields+are+required"
            }
        end

        local customer = Customer:create({
            first_name = first_name,
            middle_name = middle_name,
            last_name = last_name,
            suffix_name = suffix_name,
            phone_number = phone_number,
            email = email,
            address1 = address1,
            address2 = address2,
            city = city,
            state = state,
            zip_code = zip_code
        })

        if customer then
            return {
                redirect_to = "/customers"
            }
        else
            return {
                redirect_to = "/customers/create?error_message=Failed+to+create+customer"
            }
        end
    end
}))

-- Customer edit route
app:match("edit_customer", "/customers/:id/edit", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        local customer = Customer:find(self.params.id)
        if not customer then
            return {
                status = 404,
                render = "404"
            }
        end
        self.customer = customer
        self.title = "Edit Customer"
        return {
            render = "customers-add-edit"
        }
    end,

    POST = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        local customer = Customer:find(self.params.id)
        if not customer then
            return {
                status = 404,
                render = "404"
            }
        end

        local first_name = self.params.first_name
        local middle_name = self.params.middle_name
        local last_name = self.params.last_name
        local suffix_name = self.params.suffix_name
        local phone_number = self.params.phone_number
        local email = self.params.email
        local address1 = self.params.address1
        local address2 = self.params.address2
        local city = self.params.city
        local state = self.params.state
        local zip_code = self.params.zip_code

        if not first_name or not last_name then
            return {
                redirect_to = "/customers/" .. customer.id .. "/edit?error_message=All+fields+are+required"
            }
        end

        -- Update the customer
        customer:update({
            first_name = first_name,
            middle_name = middle_name,
            last_name = last_name,
            suffix_name = suffix_name,
            phone_number = phone_number,
            email = email,
            address1 = address1,
            address2 = address2,
            city = city,
            state = state,
            zip_code = zip_code
        })
        return {
            redirect_to = "/customers"
        }
    end
}))

-- View customer route
app:match("view_customer", "/customers/:id", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end
        local customer = Customer:find(self.params.id)
        if not customer then
            return {
                status = 404,
                render = "404"
            }
        end
        self.customer = customer
        self.title = "Customer Details"
        return {
            render = "customers-show"
        }
    end
}))

return app
