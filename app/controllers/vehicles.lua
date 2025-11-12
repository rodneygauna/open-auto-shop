-- app/controllers/vehicles.lua
local lapis = require("lapis")
local config = require("lapis.config").get()
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Vehicle = require("models.vehicle")
local Customer = require("models.customer")
local CustomersVehicles = require("models.customers_vehicles")
local validation = require("helpers.validation")
local logger = require("helpers.logger")
local helpers = require("helpers.view_helpers")
local data = require("helpers.data_dictionaries")

-- Create a vehicles controller
local app = lapis.Application()

-- Create a vehicle and assoicate it with a customer
app:match("create_vehicle", "/vehicles/create", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        -- Get list of customers for the dropdown
        local customers = Customer:select()
        self.helpers = helpers
        self.data = data
        self.customers = customers

        -- Check if customer_id is passed in query string
        if self.params.customer_id then
            self.preselected_customer_id = tonumber(self.params.customer_id)
        end

        self.csrf_token = csrf.generate_token(self)
        self.title = "Create Vehicle"
        self.error_message = self.params.error_message
        return {
            render = "vehicles/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        csrf.assert_token(self)

        local make = tostring(self.params.make or "")
        local model = tostring(self.params.model or "")
        local year = tonumber(self.params.year)
        local vin = tostring(self.params.vin or "")
        local license_plate = tostring(self.params.license_plate or "")
        local color = tostring(self.params.color or "")
        local customer_id = tonumber(self.params.customer_id)

        -- Validate required fields
        if make == "" or model == "" or not year then
            local customers = Customer:select()
            self.customers = customers
            return validation.validation_error(self, "Make, model, and year are required", "Create Vehicle",
                "vehicles/add-edit")
        end

        -- Check if customer exists
        if not customer_id then
            local customers = Customer:select()
            self.customers = customers
            return validation.validation_error(self, "Please select a customer", "Create Vehicle", "vehicles/add-edit")
        end

        -- Create the vehicle with error handling
        local success, vehicle = pcall(function()
            return Vehicle:create({
                make = make,
                model = model,
                year = year,
                vin = vin,
                license_plate = license_plate,
                color = color
            })
        end)

        if not success then
            local customers = Customer:select()
            self.customers = customers
            return validation.validation_error(self, "Failed to create vehicle", "Create Vehicle", "vehicles/add-edit")
        end

        -- Associate vehicle with customer with error handling
        local success2, err = pcall(function()
            CustomersVehicles:create({
                customer_id = customer_id,
                vehicle_id = vehicle.id
            })
        end)

        if not success2 then
            logger.error("Vehicle association failed", {
                user_id = self.current_user.id,
                vehicle_id = vehicle.id,
                customer_id = customer_id,
                error = tostring(err)
            })
            local customers = Customer:select()
            self.customers = customers
            return validation.validation_error(self, "Failed to associate vehicle with customer", "Create Vehicle",
                "vehicles/add-edit")
        end

        -- Log successful creation
        logger.db_operation("CREATE", "Vehicle", vehicle.id, self.current_user.id)

        return {
            redirect_to = "/customers/" .. customer_id
        }
    end)
}))

-- Edit a vehicle
app:match("edit_vehicle", "/vehicles/:id/edit", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        local vehicle = Vehicle:find(self.params.id)
        if not vehicle then
            self.title = "404 - Not Found"
            self.error_message = "Vehicle not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        self.helpers = helpers
        self.data = data
        self.vehicle = vehicle
        self.csrf_token = csrf.generate_token(self)
        self.title = "Edit Vehicle"
        return {
            render = "vehicles/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        csrf.assert_token(self)

        local vehicle = Vehicle:find(self.params.id)
        if not vehicle then
            self.title = "404 - Not Found"
            self.error_message = "Vehicle not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        local make = tostring(self.params.make or "")
        local model = tostring(self.params.model or "")
        local year = tonumber(self.params.year)
        local vin = tostring(self.params.vin or "")
        local license_plate = tostring(self.params.license_plate or "")
        local color = tostring(self.params.color or "")

        -- Validate required fields
        if make == "" or model == "" or not year then
            local customers = Customer:select()
            self.customers = customers
            self.vehicle = vehicle
            return validation.validation_error(self, "Make, model, and year are required", "Edit Vehicle",
                "vehicles/add-edit")
        end

        -- Update the vehicle with error handling
        local success, err = pcall(function()
            vehicle:update({
                make = make,
                model = model,
                year = year,
                vin = vin,
                license_plate = license_plate,
                color = color
            })
        end)

        if not success then
            logger.error("Vehicle update failed", {
                user_id = self.current_user.id,
                vehicle_id = vehicle.id,
                error = tostring(err)
            })
            local customers = Customer:select()
            self.customers = customers
            self.vehicle = vehicle
            return validation.validation_error(self, "Failed to update vehicle", "Edit Vehicle", "vehicles/add-edit")
        end

        -- Log successful update
        logger.db_operation("UPDATE", "Vehicle", vehicle.id, self.current_user.id)

        -- Get the customer_id from CustomersVehicles to redirect back
        local cv = CustomersVehicles:find({
            vehicle_id = vehicle.id
        })
        local customer_id = cv and cv.customer_id or nil

        if customer_id then
            return {
                redirect_to = "/customers/" .. customer_id
            }
        else
            return {
                redirect_to = "/customers"
            }
        end
    end)
}))

-- View a vehicle
app:match("show_vehicle", "/vehicles/:id", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        local vehicle = Vehicle:find(self.params.id)
        if not vehicle then
            self.title = "404 - Not Found"
            self.error_message = "Vehicle not found"
            return {
                status = 404,
                render = "errors/404"
            }
        end

        -- Get the customer associated with this vehicle
        local cv = CustomersVehicles:find({
            vehicle_id = vehicle.id
        })
        local customer = nil
        if cv then
            customer = Customer:find(cv.customer_id)
        end

        self.helpers = helpers
        self.data = data
        self.vehicle = vehicle
        self.customer = customer
        self.title = vehicle.year .. " " .. vehicle.make .. " " .. vehicle.model
        return {
            render = "vehicles/show"
        }
    end
}))

return app
