local cjson = require("cjson")
local user_idx_counter = 0

local file, err = io.open("./users.json", "r")
if not file then
    io.stderr:write("ERROR: Cannot open users.json: " .. tostring(err) .. "\n")
    os.exit(1)
end

local content = file:read("*a")
file:close()

local ok, users = pcall(cjson.decode, content)
if not ok or type(users) ~= "table" or #users == 0 then
    io.stderr:write("ERROR: Failed to parse users.json or no users found.\n")
    os.exit(1)
end

local method = os.getenv("REQUEST_METHOD") or "GET"

function request()
    user_idx_counter = user_idx_counter + 1

    local current_user_index = ((user_idx_counter - 1) % #users) + 1
    local current_user = users[current_user_index]

    local user_id = current_user.user_id
    local token = current_user.user_token
    local body = current_user.payload or {}
    local headers = {
        ["Authorization"] = "Bearer " .. token,
        ["X-User-Id"] = tostring(user_id),
        ["Content-Type"] = "application/json"
    }

    local has_body = next(body) ~= nil

    if has_body then
        headers["Content-Type"] = "application/json"
        wrk.body = cjson.encode(body)
    else
        wrk.body = nil
    end

    wrk.headers = headers
    wrk.method = method

    return wrk.format(wrk.url)
end
