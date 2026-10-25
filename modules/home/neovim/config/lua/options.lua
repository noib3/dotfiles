-- Automatically set the cwd to the one containing the currently focused
-- buffer.
vim.o.autochdir = true

vim.o.background = "dark"

-- Paste from/copy to system clipboard via OSC 52, let the terminal worry about
-- the platform-specific details.
vim.g.clipboard = "osc52"

-- Use the system clipboard.
vim.o.clipboard = "unnamedplus"

-- Only show the command line when in command mode.
vim.o.cmdheight = 0

-- Display a vertical column after `textwidth`.
vim.o.colorcolumn = "+1"

-- Automatically expand tabs to spaces.
vim.o.expandtab = true

-- Make the embedded :terminal's default cursor a vertical one.
vim.opt.guicursor:append("t:ver25-blinkon0")

-- Ignore upper/lower casing in search results.
vim.o.ignorecase = true

-- Make the statusline global.
vim.o.laststatus = 3

-- Specify the glyphs to mark newlines, tabs and spaces with.
vim.o.list = true
vim.o.listchars = "eol:¬,tab:⇥ ,space:·"

-- Modelines are a dumb antipattern.
vim.o.modeline = false

-- Enable mouse support in normal and visual mode.
vim.o.mouse = "nv"

-- Show line numbers.
vim.o.number = true

-- Maximum height for the completion menu.
vim.o.pumheight = 7

-- Show other line numbers relative to the current one.
vim.o.relativenumber = true

-- If possible show at least this many lines before and after the current
-- line.
vim.o.scrolloff = 1

-- Show an arrow at the start of wrapped lines.
vim.o.showbreak = "↪ "

-- Don't show the current mode in Insert, Replace or Visual mode.
vim.o.showmode = false

-- Only match upper case characters when the search pattern contains upper
-- cased characters (overrides `ignorecase`).
vim.o.smartcase = true

-- Add the new window to the *right* of the current one when splitting
-- vertically.
vim.o.splitright = true

-- Add the new window *below* the current one when splitting horizontally.
vim.o.splitbelow = true

-- Swap files are evil.
vim.o.swapfile = false

-- Number of spaces a <Tab> will expand to if `expandtab` is set.
vim.o.tabstop = 4

-- Enable 24-bit RGB colors.
vim.o.termguicolors = true

-- Automatically insert a newline after this many characters.
vim.o.textwidth = 80

-- Save the undo history in a file.
vim.o.undofile = true

-- Wait this many milliseconds before triggering the `CursorHold` event.
vim.o.updatetime = 500
