local vim_opt = vim.opt

local options = {
  -- Automatically set the current working directory to the one of the
  -- currently focused buffer.
  autochdir = true,

  -- Yank, delete, change etc. to and from the system clipboard.
  clipboard = 'unnamedplus',

  -- Display a vertical column at 80 characters.
  colorcolumn = '80',

  -- Do not automatically insert completion items until one is explicitly
  -- selected (no idea how this isn't the default behaviour), and show the
  -- popup menu even when there's a single completion item.
  completeopt = 'menuone,noinsert',

  -- Automatically expand tabs to spaces.
  expandtab = true,

  -- Fill `foldtext` with spaces.
  fillchars = 'fold: ',

  -- Open files will all fold levels opened.
  foldlevelstart = 99,

  -- Enable tree-sitter based folding
  foldmethod = 'expr',
  foldexpr = 'nvim_treesitter#foldexpr()',

  foldtext = 'g:FoldText()',

  -- Enable marking some characters with particular glyphs.
  list = true,

  -- Specify the glyphs to mark newlines, tabs and spaces with (needs `list` to
  -- be set).
  listchars = 'eol:¬,tab:⇥ ,space:·',

  -- Keep a buffer in memory if it gets temporarily abandoned.
  hidden = true,

  -- Ignore upper or lower casing in search results.
  ignorecase = true,

  -- Enable mouse support in normal and visual mode.
  mouse = 'nv',

  -- Show line numbers.
  number = true,

  -- Maximum height for the completion menu.
  pumheight = 7,

  -- Show other line numbers relative to the current one.
  relativenumber = true,

  -- If possible show at least this many lines before and after the current
  -- line.
  scrolloff = 1,

  -- Number of spaces inserted when indenting with `<<` and `>>`.
  shiftwidth = 2,

  -- Show an arrow at the start of wrapped lines.
  showbreak = '↪ ',

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
  tabstop = 2,

  -- Enable 24-bit RGB colors.
  termguicolors = true,

  -- Automatically insert a newline after this many characters.
  textwidth = 79,

  -- Save undo history to a file.
  undofile = true,

  -- Wait this many milliseconds before triggering the `CursorHold` event.
  updatetime = 1000,
}

vim.cmd([[
  function! g:FoldText()
    " return 'ciaone'
    let l:title = getline(v:foldstart)
    let l:column = 78
    let l:nlines = v:foldend - v:foldstart + 1
    let l:format = '%s %s %s lines'

    " Calculate how many filler characters should be displayed
    let l:fill_num =
      \ l:column + 1 - strchars(printf(l:format, l:title, '', l:nlines))

    " If the fold title is too long cut it short and add three dots at the end
    " of it.
    if fill_num < 0
      let l:title =
        \ substitute(
        \   l:title, '\(.*\)\(.\{' . (-l:fill_num + 2) . '\}\)', '\1...', ''
        \ )
    endif

    return
      \ printf(l:format, l:title, repeat('·', l:fill_num), l:nlines)
  endfunction
]])

local setup = function()
  -- Consider underscores as `word` delimiters.
  vim_opt.iskeyword:remove({'_'})

  for k, v in pairs(options) do
    vim_opt[k] = v
  end
end

return {
  setup = setup,
}
