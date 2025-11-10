-- app/controllers/customers.lua
local lapis = require("lapis")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")

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
            render = "customers/index"
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
        self.csrf_token = csrf.generate_token(self)
        self.title = "Create Customer"
        self.error_message = self.params.error_message
        return {
            render = "customers/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end

        csrf.assert_token(self)

        local first_name = tostring(self.params.first_name or "")
        local middle_name = tostring(self.params.middle_name or "")
        local last_name = tostring(self.params.last_name or "")
        local suffix_name = tostring(self.params.suffix_name or "")
        local phone_number = tostring(self.params.phone_number or "")
        local email = tostring(self.params.email or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")

        -- Validate required fields
        if first_name == "" or last_name == "" then
            self.error_message = "First name and last name are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Create Customer"
            return {
                status = 400,
                render = "customers/add-edit"
            }
        end

        -- Strip the phone number to digits only
        phone_number = phone_number:gsub("%D", "")

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

        return {
            redirect_to = "/customers/" .. customer.id
        }
    end)
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
        self.csrf_token = csrf.generate_token(self)
        self.title = "Edit Customer"
        return {
            render = "customers/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end

        csrf.assert_token(self)

        local customer = Customer:find(self.params.id)
        if not customer then
            return {
                status = 404,
                render = "404"
            }
        end

        local first_name = tostring(self.params.first_name or "")
        local middle_name = tostring(self.params.middle_name or "")
        local last_name = tostring(self.params.last_name or "")
        local suffix_name = tostring(self.params.suffix_name or "")
        local phone_number = tostring(self.params.phone_number or "")
        local email = tostring(self.params.email or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")

        -- Validate required fields
        if first_name == "" or last_name == "" then
            self.error_message = "First name and last name are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Edit Customer"
            self.customer = customer
            return {
                status = 400,
                render = "customers/add-edit"
            }
        end

        -- Strip the phone number to digits only
        phone_number = phone_number:gsub("%D", "")

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
            redirect_to = "/customers/" .. customer.id
        }
    end)
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
        local vehicles = Vehicle:select("WHERE id IN (SELECT vehicle_id FROM customers_vehicles WHERE customer_id = ?)",
            customer.id)
        self.customer = customer
        self.vehicles = vehicles
        self.title = "Customer Details"
        return {
            render = "customers/show"
        }
    end
}))

return app
