-- Test async functionality with larger file sets
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
        end,
        glob = function(pattern, nosuf, list)
            -- Return mock daily notes files
            return {
                "/tmp/test-notes/2025-01-30.md",
                "/tmp/test-notes/2025-01-31.md",
                "/tmp/test-notes/not-a-daily-note.txt",
                "/tmp/test-notes/2024-12-25.md",
                "/tmp/test-notes/2025-02-01.md",
                "/tmp/test-notes/2025-02-15.md",
                "/tmp/test-notes/2025-03-01.md",
                "/tmp/test-notes/2025-03-15.md",
                "/tmp/test-notes/2025-04-01.md",
                "/tmp/test-notes/2025-05-01.md"
            }
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
        -- In test environment, execute immediately to simulate async behavior
        print("Mock: Executing deferred function after " .. delay .. "ms delay")
        fn()
    end,
    uv = {
        fs_scandir = function(path)
            return {
                -- Mock handle that returns our test files
                next_count = 0,
                files = {
                    {name = "2025-01-30.md", type = "file"},
                    {name = "2025-01-31.md", type = "file"},
                    {name = "not-a-daily-note.txt", type = "file"},
                    {name = "2024-12-25.md", type = "file"},
                    {name = "2025-02-01.md", type = "file"},
                    {name = "2025-02-15.md", type = "file"},
                    {name = "2025-03-01.md", type = "file"},
                    {name = "2025-03-15.md", type = "file"},
                    {name = "2025-04-01.md", type = "file"},
                    {name = "2025-05-01.md", type = "file"}
                }
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

local daily_notes_index = require("daily-notes-index")

print("=== Testing Async Functionality ===")

-- Test setup
daily_notes_index.setup({
    daily_notes_folder = "/tmp/test-notes",
    index_filename = "test-index.md",
    index_title = "Test Daily Notes"
})

print("\n1. Testing sync_index async processing:")
daily_notes_index.sync_index()

print("\n2. Testing update_index async processing:")
daily_notes_index.update_index("/tmp/test-notes/2025-06-01.md", "/tmp/test-notes/test-index.md")

print("\n=== Async Tests Completed ===")
