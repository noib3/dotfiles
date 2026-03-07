local opt = vim.opt

-- Automatically set the cwd to the one containing the currently focused
-- buffer.
opt.autochdir = true

opt.background = "dark"

-- Use the system clipboard.
opt.clipboard = "unnamedplus"

-- Only show the command line when in command mode.
opt.cmdheight = 0

-- Display a vertical column after `textwidth`.
opt.colorcolumn = "+1"

-- Automatically expand tabs to spaces.
opt.expandtab = true

-- Ignore upper/lower casing in search results.
opt.ignorecase = true

-- Make the statusline global.
opt.laststatus = 3

-- Specify the glyphs to mark newlines, tabs and spaces with.
opt.list = true
opt.listchars = "eol:¬,tab:⇥ ,space:·"

-- Enable mouse support in normal and visual mode.
opt.mouse = "nv"

-- Show line numbers.
opt.number = true

-- Maximum height for the completion menu.
opt.pumheight = 7

-- Show other line numbers relative to the current one.
opt.relativenumber = true

-- If possible show at least this many lines before and after the current
-- line.
opt.scrolloff = 1

-- Show an arrow at the start of wrapped lines.
opt.showbreak = "↪ "

-- Don't show the current mode in Insert, Replace or Visual mode.
opt.showmode = false

-- Only match upper case characters when the search pattern contains upper
-- cased characters (overrides `ignorecase`).
opt.smartcase = true

-- Add the new window to the *right* of the current one when splitting
-- vertically.
opt.splitright = true

-- Add the new window *below* the current one when splitting horizontally.
opt.splitbelow = true

-- Swap files are evil.
opt.swapfile = false

-- Number of spaces a <Tab> will expand to if `expandtab` is set.
opt.tabstop = 4

-- Enable 24-bit RGB colors.
opt.termguicolors = true

-- Automatically insert a newline after this many characters.
opt.textwidth = 80

-- Save the undo history in a file.
opt.undofile = true

-- Wait this many milliseconds before triggering the `CursorHold` event.
opt.updatetime = 500
