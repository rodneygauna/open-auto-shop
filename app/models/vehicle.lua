-- app/models/vehicle.lua
local Model = require("lapis.db.model").Model

local Vehicle = Model:extend("vehicles", {
    primary_key = "id",
    timestamp = true,

    relations = {{
        "customer_vehicles",
        has_many = "CustomersVehicles",
        key = "vehicle_id"
    }}
})

-- Helper method to get the primary customer for a vehicle
function Vehicle:get_customer()
    local CustomersVehicles = require("models.customers_vehicles")
    local Customer = require("models.customer")

    local cv = CustomersVehicles:find({
        vehicle_id = self.id
    })
    if cv then
        return Customer:find(cv.customer_id)
    end
    return nil
end

return Vehicle
