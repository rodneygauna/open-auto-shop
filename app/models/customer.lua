-- app/models/customer.lua
local Model = require("lapis.db.model").Model

local Customer = Model:extend("customers", {
    primary_key = "id",
    timestamp = true,

    relations = {{
        "vehicles",
        has_many = "CustomersVehicles",
        key = "customer_id"
    }}
})

-- Helper method to get all vehicles for a customer
function Customer:get_vehicles()
    local CustomersVehicles = require("models.customers_vehicles")
    local Vehicle = require("models.vehicle")
    local db = require("lapis.db")

    local results = db.query([[
        SELECT v.* FROM vehicles v
        INNER JOIN customers_vehicles cv ON v.id = cv.vehicle_id
        WHERE cv.customer_id = ?
        ORDER BY v.year DESC, v.make, v.model
    ]], self.id)

    return results
end

return Customer
