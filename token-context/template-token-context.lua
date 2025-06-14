local users = {
    -- USERS_PLACEHOLDER
    -- Example: { id = "user_uuid_1", token = "token-user-1" },
    --          { id = "user_uuid_2", token = "token-user-2" },
}

if #users == 0 then
    io.stderr:write("ERROR: No user configured in Lua script. Check .env and execution script.\n")
    os.exit(1)
end

local cjson = require("cjson")
local user_idx_counter = 0

local current_expected_data = nil

function request()
    user_idx_counter = user_idx_counter + 1

    local current_user_index = ((user_idx_counter - 1) % #users) + 1
    local current_user = users[current_user_index]

    local expected_token = current_user.token
    local expected_user_id = current_user.id

    local headers = {
        ["Authorization"] = "Bearer " .. expected_token,
        ["X-User-Id"] = tostring(expected_user_id)
    }

    current_expected_data = { token = expected_token, userId = expected_user_id }

    wrk.headers = headers

    return wrk.format("GET", wrk.url)
end

function response(status, headers, body)
    local expected_data = current_expected_data

    local expected_token = expected_data.expected_token or "N/A"
    local expected_user_id = expected_data.expected_user_id or 0

    if status ~= 200 then
        local requestName = "user: " .. expected_user_id .. ", token: " .. expected_token
        io.stderr:write("ERROR: Unexpected status: (" .. status .. ") to " .. requestName .. "\n")
        wrk.errors = (wrk.errors or 0) + 1
        return
    end

    local success, parsed_data = pcall(cjson.decode, body)

    if not success then
        io.stderr:write("ERROR: Failed to parse JSON from response: " .. parsed_data .. ". Body: " .. body .. "\n")
        wrk.errors = (wrk.errors or 0) + 1
        return
    end

    local received_token = parsed_data.data and parsed_data.data.token
    local received_user_id = parsed_data.data and parsed_data.data.userId

    if not received_token or not received_user_id then
        io.stderr:write("ERROR: API response does not contain expected 'token' or 'userId' in 'data' field. Body: " .. body .. "\n")
        wrk.errors = (wrk.errors or 0) + 1
        return
    end

    local token_match = (received_token == expected_token)
    local user_id_match = (tostring(received_user_id) == tostring(expected_user_id))

    if not token_match then
        io.stderr:write("SECURITY ALERT: Token Leak Detected!\n")
        io.stderr:write("  Expected Token: " .. expected_token .. "\n")
        io.stderr:write("  Received Token: " .. received_token .. "\n")
        io.stderr:write("  Expected User ID (for this token): " .. expected_user_id .. "\n")
        io.stderr:write("  Received User ID (with this token): " .. received_user_id .. "\n")
        wrk.errors = (wrk.errors or 0) + 1
    end

    if not user_id_match then
        io.stderr:write("SECURITY ALERT: Inconsistent User ID detected!\n")
        io.stderr:write("  Associated Token (received): " .. received_token .. "\n")
        io.stderr:write("  Expected User ID: " .. expected_user_id .. "\n")
        io.stderr:write("  Received User ID: " .. received_user_id .. "\n")
        wrk.errors = (wrk.errors or 0) + 1
    end

    current_expected_data = nil
end

function done(summary, latency, requests)
    io.write("\n-------------------------------------\n")
    io.write("Authentication Isolation Test Results:\n")
    io.write("Total Requests: " .. summary.requests .. "\n")
    io.write("Average Latency (p50): " .. summary.latency.p50 .. "\n")
    io.write("90th Percentile Latency (p90): " .. summary.latency.p90 .. "\n")
    io.write("Requests/second (rate): " .. string.format("%.2f", summary.requests / summary.duration) .. "\n")
    io.write("HTTP Errors (e.g. 404, 500): " .. summary.errors .. "\n")
    io.write("Validation Errors (leak or inconsistency): " .. (wrk.errors or 0) .. "\n") -- wrk.errors é nosso contador customizado

    if (wrk.errors or 0) > 0 then
        io.write("=========================================================\n")
        io.write("WARNING: VALIDATION ERRORS OR POSSIBLE TOKEN OR USER ID LEAKS HAVE BEEN DETECTED!\n")
        io.write("Review the logs above for details. (stderr output)\n")
        io.write("=========================================================\n")
    else
        io.write("Congratulations! No token leaks or inconsistent User IDs detected.\n")
    end
    io.write("-------------------------------------\n")
end