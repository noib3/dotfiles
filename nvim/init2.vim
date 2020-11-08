call plug#begin('~/.config/nvim/plugged')
  Plug 'dense-analysis/ale'
  Plug 'jiangmiao/auto-pairs'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'Yggdroot/indentLine'
  " Plug 'norcalli/nvim-colorizer.lua'
  " Plug 'pacha/vem-tabline'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'embear/vim-localvimrc'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-scriptease'
  Plug 'tpope/vim-surround'
  Plug 'kana/vim-textobj-user'
  Plug 'lervag/vimtex'

  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'elzr/vim-json'
  Plug 'dag/vim-fish'

  Plug 'joshdick/onedark.vim'
  Plug 'danilo-augusto/vim-afterglow'
call plug#end()

runtime! general/**/*.vim
