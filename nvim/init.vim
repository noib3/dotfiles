" Plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'lervag/vimtex'
call plug#end()

" Basics
set tabstop=4
set shiftwidth=4
set expandtab
set number
set relativenumber

" Aliases
nnoremap <C-s> :w<cr>
inoremap <C-s> <esc>:w<cr>a

nnoremap <C-w> :q<cr>
inoremap <C-w> <esc>:q<cr>

inoremap ( ()<esc>i
inoremap [ []<esc>i
inoremap { {}<esc>i

nnoremap p P
nnoremap P p

nnoremap S :%s//g<Left><Left>

" Colorscheme
set background=dark
colorscheme gruvbox
hi Normal ctermbg=none

" Airline
let g:airline_theme='gruvbox'
let g:airline_section_z='Col: %02v/%02{col("$")-1}   Ln: %3l/%L'

" VimTeX
let g:vimtex_view_method='skim'
nnoremap <C-t> <Leader>ll
inoremap <C-t> <Leader>ll

" Disable auto-comments on new line
 autocmd Filetype * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
