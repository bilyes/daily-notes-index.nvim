# AGENTS.md

This file contains guidelines and development information for agentic coding agents working on the daily-notes-index.nvim Neovim plugin.

## Project Overview

This is a Neovim plugin that automatically maintains an index file for daily notes in Markdown format. The plugin detects when daily notes are saved, extracts date information from filenames, and updates a chronologically organized index file.

- **Main language**: Lua (Neovim plugin API)
- **Target**: Neovim 0.11.0+
- **Total code**: ~400 lines across 3 main files
- **Test runner**: LuaJIT with custom test harness

## Build/Lint/Test Commands

### Running Tests
```bash
# Run all tests
cd tests && LUA_PATH="../lua/?.lua;../lua/?/init.lua;;" luajit init.lua

# Run specific test scenarios
# The test file is structured as a single script - modify tests/init.lua to target specific functions
```

### Linting/Formatting
No automated linting or formatting tools are currently configured. When adding linting, prefer:
- **Formatter**: stylua (if added)
- **Linter**: luacheck (if added)

## Code Style Guidelines

### File Organization
- `plugin/daily-notes-index.lua` - Entry point, autocommands, user commands
- `lua/daily-notes-index/init.lua` - Core functionality and API
- `tests/init.lua` - Test suite with vim API mocks

### Naming Conventions
- **Functions**: snake_case (e.g., `update_index`, `is_daily_note`)
- **Variables**: snake_case (e.g., `daily_notes_folder`, `index_path`)
- **Local functions**: Prefix with underscore for private functions (e.g., `_build_index_content`)
- **Constants**: UPPER_SNAKE_CASE (rare, but prefer descriptive names)
- **Module table**: Use `local M = {}` pattern

### Module Structure
```lua
local M = {}

-- Default configuration
local default_config = { ... }

-- Private functions
local function _helper_function() ... end

-- Public API functions
function M.public_function() ... end

-- Setup function
function M.setup(opts) ... end

return M
```

### Import Patterns
- Use `require("daily-notes-index")` for the main module
- No external dependencies except vim API
- Keep all functionality within the plugin namespace

### Error Handling
- Return early from functions when validation fails
- Use early return/continue pattern in loops to minimize indentation (use `goto continue` in Lua)
- Prefer early validation and exit over deeply nested conditionals
- Use `vim.notify()` for user-facing messages with appropriate log levels
- Use `error()` for critical setup failures (missing required config)
- Always validate date ranges (year 2000-2100, month 1-12, day 1-31)

### String Patterns
- Use Lua pattern matching, not regex
- Escape special characters in patterns with `%` when needed
- Common patterns:
  - Date: `(%d%d%d%d)%-?(%d%d)%-?(%d%d)`
  - File paths: Use `vim.fn.expand()` for `~` expansion
  - Markdown links: `^%- %[([^%]]+)%]%(([^)]+)%)$`

### Table Operations
- Use `vim.tbl_deep_extend("force", ...)` for deep merging configs
- Use `vim.deepcopy()` for copying tables
- Prefer `ipairs` for arrays, `pairs` for objects

### Neovim API Usage
- Use `vim.api.nvim_create_augroup()` for autocmd groups
- Use `vim.api.nvim_create_autocmd()` for autocommands
- Use `vim.api.nvim_create_user_command()` for commands
- Use `vim.fn.*` for vimscript functions
- Use `vim.cmd.*` for vim commands

### Documentation Comments
- Use `@param` and `@return` tags for public functions
- Describe function purpose clearly
- Include parameter types (`string`, `table`, `boolean`, `nil`)

### Configuration Management
- Always provide default values
- Require `daily_notes_folder` in setup (validation with error)
- Expand `~` paths using `vim.fn.expand()`
- Use `vim.deepcopy()` when returning config to prevent external mutation

### Testing Guidelines
- Mock all vim API functions in tests (see tests/init.lua)
- Use print statements for test output
- Test both success and error paths
- Verify configuration changes don't affect default state
- Test date validation logic thoroughly

### Performance Considerations
- Parse index file only when necessary
- Check for duplicate entries before adding
- Use efficient string operations
- Minimize file I/O operations

### Security Notes
- Validate all user input (file paths, dates)
- Don't execute arbitrary commands
- Use relative paths in markdown links
- Handle file system errors gracefully

## Development Workflow

1. **Adding Features**:
   - Add public functions to module table `M`
   - Keep backward compatibility
   - Update README.md for new API functions and user commands
   - Update doc/daily-notes-index.txt for new functions and commands (Vim help format)
   - Update documentation for significant new features
   - When uncertain about documentation scope, use the `question` tool to ask the user if updates are needed
   - Add tests for new functionality

2. **Bug Fixes**:
   - Focus on edge cases in date parsing and file handling
   - Test with various file path formats
   - Ensure autocommands don't interfere with other plugins

3. **Testing Changes**:
   - Run full test suite: `cd tests && LUA_PATH="../lua/?.lua;../lua/?/init.lua;;" luajit init.lua`
   - Test in actual Neovim environment for integration
   - Verify autocommands work correctly

## GitHub Workflow

When pushing changes to GitHub, follow these guidelines:

### Pre-Push Checklist
1. **Feature Completion**: Always ask for user confirmation before initiating any push to GitHub
2. **Change Review**: Review all pending changes to understand the update scope before pushing
3. **Test Validation**: Ensure all tests pass and functionality works as expected
4. **Branch Management**: Never commit directly to the main branch. Always create and commit to feature branches, then open PRs from them

### Branch and PR Guidelines
1. **Never Commit to Main**: Always create feature branches for development. Never commit directly to the main branch - all changes must go through PRs.
2. **Branch Names**: Use the `question` tool to ask for user choice when uncertain. Provide options like:
   - `feature/add-new-functionality`
   - `fix/date-parsing-issue`
   - `docs/update-readme`
   - `refactor/improve-performance`

2. **PR Titles**: Use the `question` tool to ask for user choice when uncertain. Offer options such as:
   - "Add: New feature description"
   - "Fix: Bug description"
   - "Update: Documentation improvements"
   - "Refactor: Code optimization"

3. **PR Descriptions**: Keep descriptions concise and easy to read:
   - Start with a clear one-line summary
   - Use bullet points for key changes
   - Mention any breaking changes
   - Include testing notes if relevant

### Push Process
1. Run final test suite to ensure nothing is broken
2. Use the `question` tool to ask for user confirmation before staging changes
3. Create descriptive commit messages
4. Use the `question` tool to request confirmation before pushing
5. Create PR with clear, concise description

### Example PR Description
```
## Summary
• Add automatic index file generation for daily notes
• Improve date validation logic
• Update documentation with new API

## Changes
- Enhanced date pattern matching
- Added duplicate entry prevention
- Updated README with examples

## Testing
All tests pass. Tested with various note formats.
```

## Plugin Architecture

- **Entry point**: `plugin/daily-notes-index.lua` sets up autocommands on `BufWritePost`
- **Core logic**: `lua/daily-notes-index/init.lua` handles index management
- **Pattern matching**: Detects daily notes by `YYYY-MM-DD` in filenames
- **Index format**: Markdown with year/month headers, reverse chronological entries

## Common Patterns

```lua
-- Configuration validation
if not config.daily_notes_folder then
    vim.notify("daily-notes-index: Plugin not configured", vim.log.levels.ERROR)
    return
end

-- Date extraction and validation
local year, month, day = path:match("(%d%d%d%d)%-?(%d%d)%-?(%d%d)")
if not year or not month or not day then
    return
end
year = tonumber(year)
month = tonumber(month)
day = tonumber(day)
if year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
    return
end

-- File operations
if vim.fn.filereadable(path) == 1 then
    local content = table.concat(vim.fn.readfile(path), "\n")
    -- process content
end
```