-- app/models/business.lua
local Model = require("lapis.db.model").Model

local Business = Model:extend("business_info", {
    primary_key = "id",
    timestamp = true
})

return Business
