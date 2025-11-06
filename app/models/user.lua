-- app/models/user.lua
local Model = require("lapis.db.model").Model

local User = Model:extend("users", {
    primary_key = "id",
    timestamp = true
})

return User
