-- app/app.lua
local lapis = require("lapis")
local csrf = require("lapis.csrf")
local User = require("models.user")
local helpers = require("helpers.view_helpers")
local data = require("helpers.data_dictionaries")

-- Create the main application
local app = lapis.Application()

-- Enable etlua template engine
app:enable("etlua")

-- Set the layout
app.layout = "layout"

-- Before filter to load current user and helpers
app:before_filter(function(self)
    if self.session.current_user_id then
        self.current_user = User:find(self.session.current_user_id)
    end
    -- Make helpers and data dictionaries available to all views
    self.helpers = helpers
    self.data = data
end)

-- Include auth routes
local Auth = require("controllers.auth")
app:include(Auth)

-- Include business routes
local Business = require("controllers.business")
app:include(Business)

-- Include settings routes
local Settings = require("controllers.settings")
app:include(Settings)

-- Include customers routes
local Customers = require("controllers.customers")
app:include(Customers)

-- Include vehicles routes
local Vehicles = require("controllers.vehicles")
app:include(Vehicles)

-- Define the index route
app:match("index", "/", function(self)
    self.csrf_token = csrf.generate_token(self)
    return {
        render = true,
        current_user = self.current_user
    }
end)

return app
