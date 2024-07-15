local opt = vim.opt

-- Automatically set the current working directory to the one of the currently
-- focused buffer.
opt.autochdir = true

opt.background = "dark"

-- Yank, delete, change etc. to and from the system clipboard.
opt.clipboard = "unnamedplus"

-- Display a vertical column after `textwidth`.
opt.colorcolumn = "+1"

-- Automatically expand tabs to spaces.
opt.expandtab = true

-- Specify the glyphs to mark newlines, tabs and spaces with.
opt.list = true
opt.listchars = "eol:¬,tab:⇥ ,space:·"

-- Ignore upper/lower casing in search results.
opt.ignorecase = true

-- Enable mouse support in normal and visual mode.
opt.mouse = "nv"

-- Show line numbers.
opt.number = true

-- Maximum height for the completion menu.
opt.pumheight = 7

-- Show other line numbers relative to the current one.
opt.relativenumber = true

-- If possible show at least this many lines before and after the current line.
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
opt.tabstop = 2

-- Enable 24-bit RGB colors.
opt.termguicolors = true

-- Automatically insert a newline after this many characters.
opt.textwidth = 79

-- Save undo history to a file.
opt.undofile = true

-- Wait this many milliseconds before triggering the `CursorHold` event.
opt.updatetime = 1000

-- Consider underscores as `word` delimiters.
opt.iskeyword:remove({ "_" })
