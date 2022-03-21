local setup = function()
  -- Automatically set the current working directory to the one of the
  -- currently focused buffer.
  vim.o.autochdir = true

  -- Deleting words with <C-w> doesn't stop at the column where insert mode was
  -- entered.
  -- vim.o.backspace = "indent,eol,nostop"

  -- Yank, delete, change etc. to and from the system clipboard.
  vim.o.clipboard = "unnamedplus"

  -- Display a vertical column at 80 characters.
  vim.o.colorcolumn = "80"

  -- Do not automatically insert completion items until one is explicitly
  -- selected (no idea how this isn't the default behaviour), and show the
  -- popup menu even when there's a single completion item.
  vim.o.completeopt = "menuone,noinsert"

  -- Automatically expand tabs to spaces.
  vim.o.expandtab = true

  -- Fill `foldtext` with spaces.
  vim.o.fillchars = "fold: "

  -- Open files will all fold levels opened.
  vim.o.foldlevelstart = 99

  -- Enable tree-sitter based folding
  vim.o.foldmethod = "expr"
  vim.o.foldexpr = "nvim_treesitter#foldexpr()"

  vim.o.foldtext = "g:FoldText()"

  -- Enable marking some characters with particular glyphs.
  vim.o.list = true

  -- Specify the glyphs to mark newlines, tabs and spaces with (needs `list` to
  -- be set).
  vim.o.listchars = "eol:¬,tab:⇥ ,space:·"

  -- Keep a buffer in memory if it gets temporarily abandoned.
  vim.o.hidden = true

  -- Ignore upper or lower casing in search results.
  vim.o.ignorecase = true

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

  -- Number of spaces inserted when indenting with `<<` and `>>`.
  vim.o.shiftwidth = 2

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
  vim.o.tabstop = 2

  -- Enable 24-bit RGB colors.
  vim.o.termguicolors = true

  -- Automatically insert a newline after this many characters.
  vim.o.textwidth = 79

  -- Save undo history to a file.
  vim.o.undofile = true

  -- Wait this many milliseconds before triggering the `CursorHold` event.
  vim.o.updatetime = 1000

  -- Consider underscores as `word` delimiters.
  vim.opt.iskeyword:remove({ "_" })
end

vim.cmd([[
  function! g:FoldText()
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

return {
  setup = setup,
}
