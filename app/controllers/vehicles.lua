-- app/controllers/vehicles.lua
local lapis = require("lapis")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local Vehicle = require("models.vehicle")
local Customer = require("models.customer")
local CustomersVehicles = require("models.customers_vehicles")

-- Create a vehicles controller
local app = lapis.Application()

-- Create a vehicle and assoicate it with a customer
app:match("create_vehicle", "/vehicles/create", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end

        -- Get list of customers for the dropdown
        local customers = Customer:select()
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
        if not self.current_user then
            return {
                redirect_to = "/"
            }
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
            -- Get customers list again for re-rendering form
            local customers = Customer:select()
            self.customers = customers
            self.error_message = "Make, model, and year are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Create Vehicle"
            return {
                status = 400,
                render = "vehicles/add-edit"
            }
        end

        -- Check if customer exists
        if not customer_id then
            local customers = Customer:select()
            self.customers = customers
            self.error_message = "Please select a customer"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Create Vehicle"
            return {
                status = 400,
                render = "vehicles/add-edit"
            }
        end

        -- Create the vehicle
        local vehicle = Vehicle:create({
            make = make,
            model = model,
            year = year,
            vin = vin,
            license_plate = license_plate,
            color = color
        })

        -- Associate vehicle with customer
        CustomersVehicles:create({
            customer_id = customer_id,
            vehicle_id = vehicle.id
        })

        return {
            redirect_to = "/customers/" .. customer_id
        }
    end)
}))

-- Edit a vehicle
app:match("edit_vehicle", "/vehicles/:id/edit", respond_to({
    GET = function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end

        local vehicle = Vehicle:find(self.params.id)
        if not vehicle then
            return {
                status = 404,
                "Vehicle not found"
            }
        end

        -- Get list of customers for the dropdown
        local customers = Customer:select()
        self.customers = customers
        self.vehicle = vehicle
        self.csrf_token = csrf.generate_token(self)
        self.title = "Edit Vehicle"
        return {
            render = "vehicles/add-edit"
        }
    end,

    POST = capture_errors(function(self)
        if not self.current_user then
            return {
                redirect_to = "/"
            }
        end

        csrf.assert_token(self)

        local vehicle = Vehicle:find(self.params.id)
        if not vehicle then
            return {
                status = 404,
                "Vehicle not found"
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
            self.error_message = "Make, model, and year are required"
            self.csrf_token = csrf.generate_token(self)
            self.title = "Edit Vehicle"
            return {
                status = 400,
                render = "vehicles/add-edit"
            }
        end

        -- Update the vehicle
        vehicle:update({
            make = make,
            model = model,
            year = year,
            vin = vin,
            license_plate = license_plate,
            color = color
        })

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
app:match("show_vehicle", "/vehicles/:id", function(self)
    if not self.current_user then
        return {
            redirect_to = "/"
        }
    end

    local vehicle = Vehicle:find(self.params.id)
    if not vehicle then
        return {
            status = 404,
            "Vehicle not found"
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

    self.vehicle = vehicle
    self.customer = customer
    self.title = vehicle.year .. " " .. vehicle.make .. " " .. vehicle.model
    return {
        render = "vehicles/show"
    }
end)

return app
