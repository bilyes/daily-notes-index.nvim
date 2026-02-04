-- plugin/daily-notes-index.lua
-- This file is automatically loaded when Neovim starts
-- It sets up the plugin's autocommands and basic initialization

-- Create autocmd group for daily notes
local daily_notes_group = vim.api.nvim_create_augroup("DailyNotesIndex", { clear = true })

-- Auto-update index when saving a daily note
vim.api.nvim_create_autocmd("BufWritePost", {
    group = daily_notes_group,
    pattern = "*",
    callback = function(args)
        local daily_notes_index = require("daily-notes-index")
        local path = args.file

        -- Get user config
        local config = daily_notes_index.get_config()

        if daily_notes_index.is_daily_note(path, config.daily_notes_folder) then
            local index_path = daily_notes_index.get_index_path(config.daily_notes_folder)
            daily_notes_index.update_index(path, index_path)
        end
    end,
    desc = "Update index when saving daily notes"
})

-- Create user command for daily notes index operations
vim.api.nvim_create_user_command("DailyNotesIndex", function(opts)
    local daily_notes_index = require("daily-notes-index")

    if opts.fargs[1] == "open" then
        daily_notes_index.open_index()
    elseif opts.fargs[1] == "sync" then
        daily_notes_index.sync_index()
    else
        vim.notify("DailyNotesIndex: Unknown subcommand. Available: open, sync", vim.log.levels.ERROR)
    end
end, {
    nargs = 1,
    complete = function()
        return { "open", "sync" }
    end,
    desc = "Daily notes index commands"
})
