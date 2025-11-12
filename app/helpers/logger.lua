-- app/helpers/logger.lua
local config = require("lapis.config").get()

local logger = {}

-- Log levels
logger.LEVEL = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

-- Get current log level from environment (default to INFO)
local current_level = logger.LEVEL.INFO
if config._name == "development" then
    current_level = logger.LEVEL.DEBUG
elseif config._name == "production" then
    current_level = logger.LEVEL.INFO
end

-- Format log message with timestamp and level
local function format_log(level_name, message, data)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_entry = string.format("[%s] [%s] %s", timestamp, level_name, message)

    if data then
        log_entry = log_entry .. " | " .. require("lapis.util").to_json(data)
    end

    return log_entry
end

-- Core logging function
local function log(level, level_name, message, data)
    if level >= current_level then
        print(format_log(level_name, message, data))
    end
end

-- Public logging functions
function logger.debug(message, data)
    log(logger.LEVEL.DEBUG, "DEBUG", message, data)
end

function logger.info(message, data)
    log(logger.LEVEL.INFO, "INFO", message, data)
end

function logger.warn(message, data)
    log(logger.LEVEL.WARN, "WARN", message, data)
end

function logger.error(message, data)
    log(logger.LEVEL.ERROR, "ERROR", message, data)
end

-- Convenience function for logging authentication events
function logger.auth(event, user_data)
    logger.info("AUTH: " .. event, user_data)
end

-- Convenience function for logging database operations
function logger.db_operation(operation, model, record_id, user_id)
    logger.info("DB: " .. operation, {
        model = model,
        record_id = record_id,
        user_id = user_id
    })
end

return logger
