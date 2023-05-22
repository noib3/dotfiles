return {
  -- Automatically set the cwd to the one containing the currently focused
  -- buffer.
  autochdir = true,
  background = "dark",
  -- Use the system clipboard.
  clipboard = "unnamedplus",
  -- Display a vertical column after `textwidth`.
  colorcolumn = "+1",
  -- Automatically expand tabs to spaces.
  expandtab = true,
  -- Specify the glyphs to mark newlines, tabs and spaces with.
  list = true,
  listchars = "eol:¬,tab:⇥ ,space:·",
  -- Ignore upper/lower casing in search results.
  ignorecase = true,
  -- Enable mouse support in normal and visual mode.
  mouse = "nv",
  -- Show line numbers.
  number = true,
  -- Maximum height for the completion menu.
  pumheight = 7,
  -- Show other line numbers relative to the current one.
  relativenumber = true,
  -- If possible show at least this many lines before and after the current
  -- line.
  scrolloff = 1,
  -- Show an arrow at the start of wrapped lines.
  showbreak = "↪ ",
  -- Don't show the current mode in Insert, Replace or Visual mode.
  showmode = false,
  -- Only match upper case characters when the search pattern contains upper
  -- cased characters (overrides `ignorecase`).
  smartcase = true,
  -- Add the new window to the *right* of the current one when splitting
  -- vertically.
  splitright = true,
  -- Add the new window *below* the current one when splitting horizontally.
  splitbelow = true,
  -- Swap files are evil.
  swapfile = false,
  -- Number of spaces a <Tab> will expand to if `expandtab` is set.
  tabstop = 4,
  -- Enable 24-bit RGB colors.
  termguicolors = true,
  -- Automatically insert a newline after this many characters.
  textwidth = 79,
  -- Save the undo history in a file.
  undofile = true,
  -- Wait this many milliseconds before triggering the `CursorHold` event.
  updatetime = 500,
}
