local M = {}

-- Format phone number for display
-- Takes a 10-digit phone string and returns (XXX) XXX-XXXX format
-- If not 10 digits, returns the original string
function M.format_phone(phone_number)
    if not phone_number or phone_number == "" then
        return ""
    end

    local phone = tostring(phone_number)
    if #phone == 10 then
        return "(" .. phone:sub(1, 3) .. ") " .. phone:sub(4, 6) .. "-" .. phone:sub(7, 10)
    else
        return phone
    end
end

-- Format full name from customer parts
function M.format_name(first, middle, last, suffix)
    local parts = {}
    table.insert(parts, first)
    if middle and middle ~= "" then
        table.insert(parts, middle)
    end
    table.insert(parts, last)
    if suffix and suffix ~= "" then
        table.insert(parts, suffix)
    end
    return table.concat(parts, " ")
end

-- Format address for display
-- Returns HTML-formatted address with line breaks
function M.format_address(address1, address2, city, state, zip_code)
    local lines = {}

    if address1 and address1 ~= "" then
        table.insert(lines, address1)
    end

    if address2 and address2 ~= "" then
        table.insert(lines, address2)
    end

    if city and city ~= "" and state and state ~= "" then
        local city_state_zip = city .. ", " .. state
        if zip_code and zip_code ~= "" then
            city_state_zip = city_state_zip .. " " .. zip_code
        end
        table.insert(lines, city_state_zip)
    end

    if #lines == 0 then
        return ""
    end

    return table.concat(lines, "<br />\n  ")
end

return M
