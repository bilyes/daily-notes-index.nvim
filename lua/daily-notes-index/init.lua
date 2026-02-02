local M = {}

-- Default configuration
local default_config = {
    index_filename = "index.md",
    index_title = "Daily Notes Index",
}

-- Global config variable
local config = vim.deepcopy(default_config)

local function _build_index_content(entries)
    local content = string.format("# %s\n", config.index_title)
    local last_year = nil
    local last_month = nil

    for _, entry in ipairs(entries) do
        if entry.year ~= last_year then
            content = content .. string.format("\n## %d\n", entry.year)
            last_year = entry.year
            last_month = nil
        end

        if entry.month_name ~= last_month then
            content = content .. string.format("\n### %s\n\n", entry.month_name)
            last_month = entry.month_name
        end

        content = content .. entry.link .. "\n"
    end

    -- remove the trailing newline
    content = content:gsub("\n$", "")

    return content
end

local function _read_index_entries(index_path)
    if vim.fn.filereadable(index_path) ~= 1 then
        return {}
    end

    local entries = {}
    local index_content = table.concat(vim.fn.readfile(index_path), "\n")
    local lines = vim.split(index_content, "\n")
    local current_year = nil
    local current_month = nil

    for _, line in ipairs(lines) do
        -- Capture year headers
        local year_match = line:match("^## (%d%d%d%d)$")
        if year_match then
            current_year = tonumber(year_match)
            current_month = nil
            goto continue
        end

        -- Capture month headers
        local month_match = line:match("^### (.+)$")
        if month_match and current_year then
            current_month = month_match
            goto continue
        end

        -- Capture note entries
        local note_entry = line:match("^%- %[([^%]]+)%]%(([^)]+)%)$")
        if note_entry and current_year and current_month then
            -- Extract date from the entry
            local entry_date_str = note_entry:match("(%d%d%d%d%-%d%d%-%d%d)")
            if entry_date_str then
                local entry_year, entry_month, entry_day = entry_date_str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
                if entry_year and entry_month and entry_day then
                    table.insert(entries, {
                        year = tonumber(entry_year),
                        month = tonumber(entry_month),
                        day = tonumber(entry_day),
                        link = line,
                        month_name = current_month
                    })
                end
            end
        end

        ::continue::
    end

    return entries
end

local function _add_entry(entries, year, month, day, note_link)
    local month_names = { "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December" }

    table.insert(entries, {
        year = year,
        month = month,
        day = day,
        link = note_link,
        month_name = month_names[month]
    })

    -- Sort entries by date (reverse chronological)
    table.sort(entries, function(a, b)
        if a.year ~= b.year then
            return a.year > b.year
        elseif a.month ~= b.month then
            return a.month > b.month
        else
            return a.day > b.day
        end
    end)

    return entries
end

local function _build_note_link(year, month, day, path_str)
    -- Get day name
    local time = os.time({ year = year, month = month, day = day })
    local day_name = os.date("%A", time)

    -- Format the link text
    local link_text = string.format("%s-%s-%s - %s", year,
        string.format("%02d", month), string.format("%02d", day), day_name)

    -- Create the markdown link with relative path
    return string.format("- [%s](%s)", link_text, path_str:gsub("%.md$", ""))
end

-- Updates the index with a new daily note entry
-- @param note_path string: The path of the newly created daily note
-- @param index_path string: The path to the index file
-- @return nil
function M.update_index(note_path, index_path)
    if not note_path or not index_path then
        return
    end

    -- Parse date components
    local year, month, day = note_path:match("(%d%d%d%d)%-?(%d%d)%-?(%d%d)")
    if not year or not month or not day then
        return -- Invalid date format
    end

    -- Convert to numbers
    year = tonumber(year)
    month = tonumber(month)
    day = tonumber(day)

    -- Validate date components
    if year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
        return -- Invalid date range
    end


    local entries = {}
    if vim.fn.filereadable(index_path) == 1 then
        -- Parse existing entries to check for duplicates
        entries = _read_index_entries(index_path)
        -- Check if this entry already exists
        for _, entry in ipairs(entries) do
            if entry.year == year and entry.month == month and entry.day == day then
                -- Don't add if it's a duplicate
                return
            end
        end
    end

    local note_link = _build_note_link(year, month, day, note_path)
    entries = _add_entry(entries, year, month, day, note_link)
    local new_content = _build_index_content(entries)

    -- Write the updated index
    vim.fn.writefile(vim.split(new_content, "\n"), index_path)
end

-- Checks if the given note path corresponds to a daily note
-- @param note_path string: The path of the note to check
-- @param daily_notes_folder_path string: The configured daily notes folder path
-- @return boolean: true if it's a daily note, false otherwise
function M.is_daily_note(note_path, daily_notes_folder_path)
    -- Check if this is a daily note in the configured folder
    return note_path:match(daily_notes_folder_path:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- Gets the path to the index file
-- @param daily_notes_folder_path string: The configured daily notes folder path
-- @return string: The path to the index file
function M.get_index_path(daily_notes_folder_path)
    return daily_notes_folder_path .. "/" .. config.index_filename
end

-- Get current configuration
-- @return table: Current plugin configuration
function M.get_config()
    return vim.deepcopy(config)
end

-- Setup function for plugin manager compatibility
-- @param opts table: Optional configuration options
function M.setup(opts)
    opts = opts or {}

    if opts.daily_notes_folder == nil then
        error("daily_notes_folder must be provided in the configuration")
    end

    -- Merge user options with defaults
    config = vim.tbl_deep_extend("force", default_config, opts)

    -- Expand tilde in paths
    if config.daily_notes_folder:match("^~/") then
        config.daily_notes_folder = vim.fn.expand(config.daily_notes_folder)
    end
end

return M
