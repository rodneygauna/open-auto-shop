-- spec/helpers/request.lua
-- Helper functions for making requests in tests
local mock_request = require("lapis.spec.request").mock_request
local csrf = require("lapis.csrf")

local request_helpers = {}

-- Generate a valid CSRF token
function request_helpers.generate_csrf_token(app)
    -- Create a mock request to generate a valid token
    local _, _, headers = mock_request(app, "/")
    local req = {
        headers = headers
    }
    return csrf.generate_token(req)
end

-- Make a GET request with CSRF token
function request_helpers.get_with_csrf(app, path, options)
    options = options or {}
    local token = request_helpers.generate_csrf_token(app)
    options.get = options.get or {}
    options.get.csrf_token = token
    return mock_request(app, path, options)
end

-- Make a POST request with CSRF token
function request_helpers.post_with_csrf(app, path, post_data, options)
    options = options or {}
    options.method = "POST"

    -- Get a valid CSRF token from a previous request
    local _, _, headers = mock_request(app, path)
    options.prev = headers

    -- Create a session to get the token
    local session = options.session or {}
    options.session = session

    -- Add CSRF token to post data
    post_data = post_data or {}
    post_data.csrf_token = csrf.generate_token({
        session = session
    })
    options.post = post_data

    return mock_request(app, path, options)
end

return request_helpers
