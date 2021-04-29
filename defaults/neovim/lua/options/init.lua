local scopes = {
  o = vim.o,
  b = vim.bo,
  w = vim.wo,
}

local function opt(scope, key, value)
  scopes[scope][key] = value
  if scope ~= 'o' then scopes['o'][key] = value end
end

opt('o', 'autochdir', true)
opt('o', 'clipboard', 'unnamedplus')
opt('o', 'completeopt', 'menuone,noinsert')
opt('o', 'fillchars', 'fold: ')
opt('o', 'listchars', 'eol:¬,tab:⇥ ,space:·')
opt('o', 'hidden', true)
opt('o', 'ignorecase', true)
opt('o', 'mouse', 'nv')
opt('o', 'scrolloff', 1)
opt('o', 'showbreak', '↪ ')
opt('o', 'smartcase', true)
opt('o', 'splitright', true)
opt('o', 'splitbelow', true)
opt('o', 'termguicolors', true)

opt('b', 'expandtab', true)
opt('b', 'iskeyword', '@,48-57,192-255')
opt('b', 'shiftwidth', 2)
opt('b', 'swapfile', false)
opt('b', 'tabstop', 2)
opt('b', 'undofile', true)

opt('w', 'colorcolumn', '80')
opt('w', 'linebreak', false)
opt('w', 'list', true)
opt('w', 'number', true)
opt('w', 'relativenumber', true)

require('options.spellfile')
