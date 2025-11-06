-- app/models/customer.lua
local Model = require("lapis.db.model").Model

local Customer = Model:extend("customers", {
    primary_key = "id",
    timestamp = true
})

return Customer
