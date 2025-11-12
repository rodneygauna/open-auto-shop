-- app/controllers/settings.lua
local lapis = require("lapis")
local config = require("lapis.config").get()
local csrf = require("lapis.csrf")
local respond_to = require("lapis.application").respond_to
local capture_errors = require("lapis.application").capture_errors
local User = require("models.user")
local Business = require("models.business")
local validation = require("helpers.validation")

-- Create a settings controller
local app = lapis.Application()

-- Settings route
app:match("settings", "/settings", respond_to({
    GET = function(self)
        local auth_error = validation.require_auth(self)
        if auth_error then
            return auth_error
        end

        -- Total user counts
        local user_count = User:count()
        self.user_count = user_count
        local business = Business:find(config.business_id)
        if business then
            self.business = business
        end
        local helpers = require("helpers.view_helpers")
        local data = require("helpers.data_dictionaries")
        self.helpers = helpers
        self.data = data
        self.csrf_token = csrf.generate_token(self)
        self.title = "User Settings"
        return {
            render = "settings/index"
        }
    end
}))

return app
