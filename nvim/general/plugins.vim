call plug#begin('~/.config/nvim/plugged')
  " Miscellaneous
  Plug 'Raimondi/delimitMate'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'embear/vim-localvimrc'
  Plug 'lervag/vimtex'

  " Completion & linting
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  " Snippets
  Plug 'SirVer/ultisnips'

  " Text objects
  Plug 'kana/vim-textobj-user'
  Plug 'somini/vim-textobj-fold'
  Plug 'thinca/vim-textobj-between'

  " tpope
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-scriptease'
  Plug 'tpope/vim-surround'

  " Statusline & bufferline
  Plug 'itchyny/lightline.vim'
  Plug 'mengelbrecht/lightline-bufferline'

  " Syntax
  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'elzr/vim-json'
  Plug 'dag/vim-fish'
  Plug 'tridactyl/vim-tridactyl'

  " Colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'danilo-augusto/vim-afterglow'
call plug#end()
