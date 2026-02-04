# daily-notes-index.nvim

A Neovim plugin that automatically maintains an index file for your daily notes in Markdown format.

## Features

- Automatically updates an index file when you save a new daily note
- Organizes entries by year and month
- Creates chronologically sorted links with day names
- Detects daily notes based on date patterns in filenames
- Configurable folder paths and index filename

## Requirements

- Neovim 0.11.0 or later

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
 {
    "bilyes/daily-notes-index.nvim",
    opts = {
        daily_notes_folder = "~/Documents/daily-notes",
        index_filename = "index.md",
        index_title = "Daily Notes Index",
    }
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "bilyes/daily-notes-index.nvim",
    config = function()
        require("daily-notes-index").setup({
            daily_notes_folder = "~/Documents/daily-notes",
            index_filename = "index.md",
            index_title = "Daily Notes Index",
        })
    end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "bilyes/daily-notes-index.nvim"
lua << EOF
require("daily-notes-index").setup({
    daily_notes_folder = "~/Documents/daily-notes",
    index_filename = "index.md",
    index_title = "Daily Notes Index",
})
EOF
```

## Configuration

The plugin can be configured through the `setup()` function:

```lua
require("daily-notes-index").setup({
    daily_notes_folder = "~/Documents/daily-notes",
    index_filename = "index.md",
    index_title = "Daily Notes Index",
})
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `daily_notes_folder` | string | `"~/Documents/daily-notes"` | The folder where your daily notes are stored |
| `index_filename` | string | `"index.md"` | The name of the index file to create/update |
| `index_title` | string | `"Daily Notes Index"` | The title/header of the index file |


## Usage

The plugin works automatically in the background. When you save a new daily note in the configured folder, it will:

1. Detect if the saved file is a daily note based on date patterns in the filename
2. Extract the date from the filename (supports formats like `2025-01-31.md`)
3. Update the index file with a new entry in the format:
   ```markdown
   - [2025-01-31 - Friday](path/to/note)
   ```
4. Organize entries by year and month in reverse chronological order

### Background Processing

The plugin processes index updates asynchronously to prevent blocking the editor, ensuring smooth operation even with large collections of daily notes.

### Daily Note Format

The plugin expects daily notes to have date patterns in their filenames. Supported formats include:
- `2025-01-31.md`
- `2025-01-31.md.md`
- Any filename containing a `YYYY-MM-DD` pattern

### Index File Format

The generated index file (`index.md` by default) will look like:

```markdown
# Daily Notes Index

## 2025

### January

- [2025-01-31 - Friday](path/to/2025-01-31)
- [2025-01-30 - Thursday](path/to/2025-01-30)
- [2025-01-29 - Wednesday](path/to/2025-01-29)

### February

- [2025-02-01 - Saturday](path/to/2025-02-01)
```

## API Functions

### `update_index(note_path, index_path)`
Manually update the index with a new daily note entry.

### `is_daily_note(note_path, daily_notes_folder_path)`
Check if a given note path corresponds to a daily note.

### `get_index_path(daily_notes_folder_path)`
Get the path to the index file.

### `get_config()`
Get the current plugin configuration.

### `setup(opts)`
Configure the plugin with user options.

## Commands

### `DailyNotesIndex open`

Opens the daily notes index file in the current buffer. If the index file doesn't exist, it will be created automatically.

```vim
:DailyNotesIndex open
```

The command handles the following scenarios:
- If the plugin is not configured, it shows an error message
- If the index file doesn't exist, it creates a new one with the configured title
- Opens the index file in the current window for immediate editing

### `DailyNotesIndex sync`

Rebuilds the entire index file from scratch by scanning the daily notes folder. This command creates a comprehensive index that reflects the current state of all daily notes.

```vim
:DailyNotesIndex sync
```

The command performs the following actions:
- Scans the configured daily notes folder for all files
- Detects daily notes based on date patterns in filenames
- Validates date ranges (years 2000-2100, valid months/days)
- Rebuilds the entire index from scratch with all found daily notes
- Removes any entries from the index that no longer exist as files
- Shows a summary of how many notes were processed

This is useful when:
- You want to create an initial index for existing daily notes
- The index file has become corrupted or out of sync
- You've manually moved or renamed daily notes
- You want to clean up orphaned entries in the index

## License

MIT License# daily-notes-index.nvim
