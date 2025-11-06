-- app/models/customers_vehicles.lua
local Model = require("lapis.db.model").Model

local CustomersVehicles = Model:extend("customers_vehicles", {
    primary_key = "id",
    timestamp = true
})

return CustomersVehicles
