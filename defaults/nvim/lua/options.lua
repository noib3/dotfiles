o  = vim.o
bo = vim.bo
wo = vim.wo

o.autochdir     = true
o.clipboard     = 'unnamedplus'
o.completeopt   = 'menuone,noinsert'
o.fillchars     = 'fold: ,vert: '
o.listchars     = 'tab:⇥ ,space:·,eol:¬'
o.hidden        = true
o.ignorecase    = true
o.laststatus    = 0
o.mouse         = 'a'
o.scrolloff     = 1
o.showbreak     = '↪ '
o.smartcase     = true
o.splitright    = true
o.splitbelow    = true
o.termguicolors = true

bo.expandtab  = true
bo.iskeyword  = '@,48-57,192-255'
bo.shiftwidth = 2
bo.spellfile  = vim.env.SECRETSDIR .. '/nvim/spell/en.utf-8.add'
bo.swapfile   = false
bo.tabstop    = 2
bo.undofile   = true

wo.colorcolumn    = '80'
wo.linebreak      = false
wo.list           = true
wo.number         = true
wo.relativenumber = true
