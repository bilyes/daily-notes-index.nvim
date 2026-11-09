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
        for _, tbl in ipairs({ ... }) do
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
        end,
        filereadable = function(path)
            return 0 -- File doesn't exist by default
        end,
        writefile = function(lines, path)
            print("Mock: Writing file to " .. path)
            return 1
        end,
        isdirectory = function(path)
            return 0
        end,
        fnamemodify = function(path, modifier)
            if modifier == ":t" then
                return path:match("/([^/]*)$") or path
            end
            return path
        end
    },
    cmd = {
        edit = function(path)
            print("Mock: Editing file " .. path)
        end
    },
    log = {
        levels = {
            ERROR = 1,
            INFO = 2
        }
    },
    notify = function(msg, level)
        print("Mock notify [" .. (level == _G.vim.log.levels.ERROR and "ERROR" or "INFO") .. "]: " .. msg)
    end,
    split = function(str, sep)
        local result = {}
        local pattern = string.format("([^%s]+)", sep)
        str:gsub(pattern, function(c) table.insert(result, c) end)
        return result
    end,
    defer_fn = function(fn, delay)
        -- In test environment, execute immediately to simulate async
        fn()
    end,
    uv = {
        fs_scandir = function(path)
            -- Mock handle that returns our test files
            return {
                files = {
                    {name = "2025-01-30.md", type = "file"},
                    {name = "2025-01-31.md", type = "file"},
                    {name = "not-a-daily-note.txt", type = "file"},
                    {name = "2024-12-25.md", type = "file"}
                },
                next_count = 0
            }
        end,
        fs_scandir_next = function(handle)
            if handle.next_count < #handle.files then
                handle.next_count = handle.next_count + 1
                local file = handle.files[handle.next_count]
                return file.name, file.type
            end
            return nil
        end
    }
}

-- Record what each mocked write puts in the index, so the tests can check its lines
local written = {}
_G.vim.fn.writefile = function(lines, path)
    print("Mock: Writing file to " .. path)
    written[path] = lines
    return 1
end

local function assert_has_line(lines, expected)
    for _, line in ipairs(lines or {}) do
        if line == expected then
            return
        end
    end
    error("Expected index line not found: " .. expected)
end

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
assert(is_daily == true, "is_daily_note missed a note in the daily notes folder")
-- Several pattern characters ("-", ".") in the folder path must not break the match
assert(daily_notes_index.is_daily_note("/home/user/my-daily-notes/2025-01-31.md", "/home/user/my-daily-notes") == true,
    "is_daily_note missed a note in a folder whose path has several pattern characters")
assert(daily_notes_index.is_daily_note("/home/user/other/2025-01-31.md", "/home/user/my-daily-notes") == false,
    "is_daily_note matched a note outside the daily notes folder")

-- Test index path generation
local index_path = daily_notes_index.get_index_path("/tmp/test-notes")
print("Index path:", index_path)

-- Test open_index function
print("\nTesting open_index function...")
daily_notes_index.open_index()

print("\nTesting open_index without config...")
-- Test error handling - we'll need to manually test this case
-- Since the module is already loaded with config, we'll verify the error message logic
print("Error handling test: open_index checks config.daily_notes_folder")
print("If config.daily_notes_folder is nil, it shows error message")
print("This is verified by the code logic in open_index function")

-- Test sync_index function
print("\nTesting sync_index function...")
-- Mock vim.fn.glob to return test files
_G.vim.fn.glob = function(pattern, nosuf, list)
    -- Return mock daily notes files
    return {
        "/tmp/test-notes/2025-01-30.md",
        "/tmp/test-notes/2025-01-31.md",
        "/tmp/test-notes/not-a-daily-note.txt",
        "/tmp/test-notes/2024-12-25.md"
    }
end

-- Mock vim.fn.isdir to return false for files
_G.vim.fn.isdir = function(path)
    return 0
end

daily_notes_index.sync_index()

local synced = written["/tmp/test-notes/test-index.md"]
assert_has_line(synced, "- [2025-01-31 - Friday](2025-01-31.md)")
assert_has_line(synced, "- [2025-01-30 - Thursday](2025-01-30.md)")
assert_has_line(synced, "- [2024-12-25 - Wednesday](2024-12-25.md)")
for _, line in ipairs(synced) do
    assert(not line:find("not-a-daily-note", 1, true), "sync_index indexed a file without a date")
end
print("sync_index links each note by filename")

-- Test update_index with new note addition
print("\nTesting update_index with new note...")
-- Mock the index file to simulate existing file without the new note
_G.vim.fn.filereadable = function(path)
    return 1 -- Simulate file exists
end

-- Mock readfile to return existing index content (without the new note)
_G.vim.fn.readfile = function(path)
    return {"# Test Daily Notes", "", "## 2025", "", "### January", "", "- [2025-01-30 - Thursday](2025-01-30.md)"}
end

-- Test adding a new note
written = {}
daily_notes_index.update_index("/tmp/test-notes/2025-01-31.md", "/tmp/test-notes/test-index.md")

local updated = written["/tmp/test-notes/test-index.md"]
assert_has_line(updated, "- [2025-01-31 - Friday](2025-01-31.md)")
assert_has_line(updated, "- [2025-01-30 - Thursday](2025-01-30.md)")
print("update_index links the new note by filename, not its full path, and keeps existing entries")

print("All tests passed!")
