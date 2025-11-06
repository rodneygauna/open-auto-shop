-- app/models/vehicle.lua
local Model = require("lapis.db.model").Model

local Vehicle = Model:extend("vehicles", {
    primary_key = "id",
    timestamp = true
})

return Vehicle
