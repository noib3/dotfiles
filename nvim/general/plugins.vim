call plug#begin('~/.config/nvim/plugged')
  " Miscellaneous
  Plug 'jiangmiao/auto-pairs'
  Plug 'junegunn/fzf'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'pacha/vem-tabline'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'embear/vim-localvimrc'
  Plug 'lervag/vimtex'

  " Completion & linting
  Plug 'dense-analysis/ale'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}

  " Text objects
  Plug 'kana/vim-textobj-user'
  Plug 'somini/vim-textobj-fold'
  Plug 'thinca/vim-textobj-between'

  " tpope
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-scriptease'
  Plug 'tpope/vim-surround'

  " Syntax
  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'elzr/vim-json'
  Plug 'dag/vim-fish'

  " Colorschemes
  Plug 'joshdick/onedark.vim'
  Plug 'danilo-augusto/vim-afterglow'
call plug#end()
