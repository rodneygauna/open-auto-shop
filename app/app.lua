-- app/app.lua
local lapis = require("lapis")
local csrf = require("lapis.csrf")
local User = require("models.user")
local Auth = require("controllers.auth")

-- Create the main application
local app = lapis.Application()

-- Enable etlua template engine
app:enable("etlua")

-- Set the layout
app.layout = "layout"

-- Before filter to load current user
app:before_filter(function(self)
    if self.session.current_user_id then
        self.current_user = User:find(self.session.current_user_id)
    end
end)

-- Include auth routes
app:include(Auth)

-- Define the index route
app:match("index", "/", function(self)
    self.csrf_token = csrf.generate_token(self)
    return {
        render = true,
        current_user = self.current_user
    }
end)

return app
