call plug#begin('~/.config/nvim/plugged')
  " Miscellaneous
  Plug 'rhysd/clever-f.vim'
  Plug 'Raimondi/delimitMate'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'shime/vim-livedown'
  Plug 'embear/vim-localvimrc'
  Plug 'timakro/vim-searchant'
  Plug 'liuchengxu/vim-which-key'

  " Completion & linting
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'dense-analysis/ale'
  Plug 'davidhalter/jedi-vim'

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

  " Language syntax
  Plug 'bfontaine/Brewfile.vim'
  Plug 'dag/vim-fish'
  Plug 'fatih/vim-go'
  Plug 'elzr/vim-json'
  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'tridactyl/vim-tridactyl'
  Plug 'lervag/vimtex'

  " Colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
  Plug 'danilo-augusto/vim-afterglow'
call plug#end()
