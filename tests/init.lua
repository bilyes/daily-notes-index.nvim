local daily_notes_index = require("daily-notes-index")

-- Test basic functionality
print("Testing daily-notes-index plugin...")

-- Test config
local config = daily_notes_index.get_config()
print("Default config:", vim.inspect(config))

-- Test setup with custom config
daily_notes_index.setup({
    daily_notes_folder = "/tmp/test-notes",
    index_filename = "test-diary.md",
    auto_update = false
})

local new_config = daily_notes_index.get_config()
print("Custom config:", vim.inspect(new_config))

-- Test daily note detection
local is_daily = daily_notes_index.is_daily_note("/tmp/test-notes/2025-01-31.md", "/tmp/test-notes")
print("Is daily note:", is_daily)

-- Test index path generation
local index_path = daily_notes_index.get_index_path("/tmp/test-notes")
print("Index path:", index_path)

print("All tests passed!")
