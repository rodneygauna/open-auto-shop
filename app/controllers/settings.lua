-- app/controllers/settings.lua
local lapis = require("lapis")
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local User = require("models.user")
local Business = require("models.business")

-- Create a settings controller
local app = lapis.Application()

-- Settings route
app:match("settings", "/settings", respond_to({
    GET = function(self)
        local business = Business:find(1)
        if business then
            self.business = business
        end
        if not self.current_user then
            return {
                redirect_to = app:url_for("index")
            }
        end
        self.csrf_token = csrf.generate_token(self)
        self.title = "User Settings"
        return {
            render = "settings"
        }
    end
}))

return app
