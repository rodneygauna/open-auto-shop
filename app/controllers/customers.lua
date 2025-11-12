-- app/controllers/customers.lua
local lapis = require("lapis")
local config = require("lapis.config").get()
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local db = require("lapis.db")
local Customer = require("models.customer")
local Vehicle = require("models.vehicle")
local validation = require("helpers.validation")
local logger = require("helpers.logger")
local helpers = require("helpers.view_helpers")
local data = require("helpers.data_dictionaries")

-- Create a customers controller
local app = lapis.Application()

-- Customers list route
app:match("customers", "/customers", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        -- Pagination setup
        local page = tonumber(self.params.page) or 1
        local per_page = config.items_per_page or 20
        local offset = (page - 1) * per_page

        -- Get total count for pagination
        local count_result = db.query("SELECT COUNT(*) as count FROM customers")
        local total_count = count_result[1].count
        local total_pages = math.ceil(total_count / per_page)

        -- Fetch customers with vehicle counts and pagination
        local customers = db.query([[
            SELECT c.*, COALESCE(COUNT(cv.vehicle_id), 0)::integer as vehicle_count
            FROM customers c
            LEFT JOIN customers_vehicles cv ON c.id = cv.customer_id
            GROUP BY c.id
            ORDER BY c.id
            LIMIT ? OFFSET ?
        ]], per_page, offset)

        self.customers = customers
        self.current_page = page
        self.total_pages = total_pages
        self.total_count = total_count
        self.per_page = per_page
        self.helpers = helpers
        self.data = data
        self.title = "Customers"
        return {
            render = "customers/index"
        }
    end
}))

-- Customer create route
app:match("create_customer", "/customers/create", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end
        self.helpers = helpers
        self.data = data
        self.csrf_token = csrf.generate_token(self)
        self.title = "Create Customer"
        self.error_message = self.params.error_message
        return {
            render = "customers/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        csrf.assert_token(self)

        local first_name = tostring(self.params.first_name or "")
        local middle_name = tostring(self.params.middle_name or "")
        local last_name = tostring(self.params.last_name or "")
        local suffix_name = tostring(self.params.suffix_name or "")
        local phone_number = validation.sanitize_phone(self.params.phone_number)
        local email = tostring(self.params.email or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")

        -- Validate required fields
        if first_name == "" or last_name == "" then
            return validation.validation_error(self, "First name and last name are required", "Create Customer",
                "customers/add-edit")
        end

        -- Create the customer with error handling
        local success, customer = pcall(function()
            return Customer:create({
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
        end)

        if not success then
            logger.error("Customer creation failed", {
                user_id = self.current_user.id,
                error = tostring(customer)
            })
            return validation.validation_error(self, "Database error: " .. tostring(customer), "Create Customer",
                "customers/add-edit")
        end

        -- Log successful creation
        logger.db_operation("CREATE", "Customer", customer.id, self.current_user.id)

        return {
            redirect_to = "/customers/" .. customer.id
        }
    end)
}))

-- Customer edit route
app:match("edit_customer", "/customers/:id/edit", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end
        local customer = Customer:find(self.params.id)
        if not customer then
            self.title = "404 - Not Found"
            return {
                status = 404,
                render = "errors/404"
            }
        end
        self.helpers = helpers
        self.data = data
        self.customer = customer
        self.csrf_token = csrf.generate_token(self)
        self.title = "Edit Customer"
        return {
            render = "customers/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        csrf.assert_token(self)

        local customer = Customer:find(self.params.id)
        if not customer then
            self.title = "404 - Not Found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        local first_name = tostring(self.params.first_name or "")
        local middle_name = tostring(self.params.middle_name or "")
        local last_name = tostring(self.params.last_name or "")
        local suffix_name = tostring(self.params.suffix_name or "")
        local phone_number = validation.sanitize_phone(self.params.phone_number)
        local email = tostring(self.params.email or "")
        local address1 = tostring(self.params.address1 or "")
        local address2 = tostring(self.params.address2 or "")
        local city = tostring(self.params.city or "")
        local state = tostring(self.params.state or "")
        local zip_code = tostring(self.params.zip_code or "")

        -- Validate required fields
        if first_name == "" or last_name == "" then
            self.customer = customer
            return validation.validation_error(self, "First name and last name are required", "Edit Customer",
                "customers/add-edit")
        end

        -- Update the customer with error handling
        local success, err = pcall(function()
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
        end)

        if not success then
            logger.error("Customer update failed", {
                user_id = self.current_user.id,
                customer_id = customer.id,
                error = tostring(err)
            })
            self.customer = customer
            return validation.validation_error(self, "Database error: " .. tostring(err), "Edit Customer",
                "customers/add-edit")
        end

        -- Log successful update
        logger.db_operation("UPDATE", "Customer", customer.id, self.current_user.id)

        return {
            redirect_to = "/customers/" .. customer.id
        }
    end)
}))

-- View customer route
app:match("view_customer", "/customers/:id", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end
        local customer = Customer:find(self.params.id)
        if not customer then
            self.title = "404 - Not Found"
            return {
                status = 404,
                render = "errors/404"
            }
        end
        local vehicles = Vehicle:select("WHERE id IN (SELECT vehicle_id FROM customers_vehicles WHERE customer_id = ?)",
            customer.id)
        self.helpers = helpers
        self.data = data
        self.customer = customer
        self.vehicles = vehicles
        self.title = "Customer Details"
        return {
            render = "customers/show"
        }
    end
}))

return app
