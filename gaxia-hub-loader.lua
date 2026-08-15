-- Gaxia Hub Loader
-- Loads the main script from private GitHub repo
-- By NotGaxia

local TOKEN = "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"
local REPO_OWNER = "Gaxia-XP"
local REPO_NAME = "gaxia-hub"
local BRANCH = "main"
local FILE_PATH = "gaxia-hub-main.lua"

local url = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/%s",
    REPO_OWNER,
    REPO_NAME,
    BRANCH,
    FILE_PATH
)

print("[Gaxia Hub] Loading from private repository...")

local success, response = pcall(function()
    return request({
        Url = url,
        Method = "GET",
        Headers = {
            ["Authorization"] = "token " .. TOKEN,
            ["Accept"] = "application/vnd.github.v3.raw"
        }
    })
end)

if not success then
    error("[Gaxia Hub] Failed to connect to GitHub: " .. tostring(response))
end

if response.StatusCode ~= 200 then
    error("[Gaxia Hub] Failed to load script (Status: " .. response.StatusCode .. ")")
end

print("[Gaxia Hub] Script loaded successfully!")
print("[Gaxia Hub] Executing...")

local executeSuccess, executeError = pcall(function()
    loadstring(response.Body)()
end)

if not executeSuccess then
    error("[Gaxia Hub] Execution error: " .. tostring(executeError))
end
