-- Mock vim functions for testing
_G.vim = {
    deepcopy = function(tbl)
        local copy = {}
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                copy[k] = _G.vim.deepcopy(v)
            else
                copy[k] = v
            end
        end
        return copy
    end,
    tbl_deep_extend = function(behavior, ...)
        local result = {}
        for _, tbl in ipairs({...}) do
            for k, v in pairs(tbl) do
                if type(v) == "table" and type(result[k]) == "table" then
                    result[k] = _G.vim.tbl_deep_extend(behavior, result[k], v)
                else
                    result[k] = v
                end
            end
        end
        return result
    end,
    fn = {
        expand = function(path)
            return path:gsub("^~", "/home/user")
        end
    }
}

local daily_notes_index = require("daily-notes-index")

-- Test basic functionality
print("Testing daily-notes-index plugin...")

-- Simple inspect function for testing
local function inspect(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    local result = "{"
    for k, v in pairs(tbl) do
        result = result .. tostring(k) .. "=" .. (type(v) == "string" and '"' .. v .. '"' or tostring(v)) .. ","
    end
    result = result .. "}"
    return result
end

-- Test config
local config = daily_notes_index.get_config()
print("Default config:", inspect(config))

-- Test setup with custom config
daily_notes_index.setup({
    daily_notes_folder = "/tmp/test-notes",
    index_filename = "test-index.md",
    index_title = "Test Daily Notes",
})

local new_config = daily_notes_index.get_config()
print("Custom config:", inspect(new_config))

-- Test daily note detection
local is_daily = daily_notes_index.is_daily_note("/tmp/test-notes/2025-01-31.md", "/tmp/test-notes")
print("Is daily note:", is_daily)

-- Test index path generation
local index_path = daily_notes_index.get_index_path("/tmp/test-notes")
print("Index path:", index_path)

print("All tests passed!")
