" ----------------------- NEOVIM CONFIG FILE ------------------------

" Plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/lightline.vim'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'tpope/vim-surround'
call plug#end()

" Basic settings
set tabstop=4
set shiftwidth=4
set expandtab
set number
set relativenumber
set noshowmode
set clipboard+=unnamedplus
set fileencoding=utf-8
set undofile
set undodir=$HOME/.cache/nvim
set undolevels=1000
set undoreload=10000
set termguicolors

" Lets
let mapleader=","
let g:is_posix=1
let g:netrw_home=$HOME.'/.cache/nvim'

" Key mappings
nnoremap <C-s> :w<cr>
inoremap <C-s> <esc>:w<cr>a
nnoremap <C-w> :q<cr>
inoremap <C-w> <esc>:q<cr>

nnoremap <C-a> ^
vnoremap <C-a> ^
inoremap <C-a> <esc>^i
nnoremap <C-e> g_
vnoremap <C-e> g_
inoremap <C-e> <esc>g_a

nnoremap <leader>w <C-w><C-k>
nnoremap <leader>a <C-w><C-h>
nnoremap <leader>s <C-w><C-j>
nnoremap <leader>d <C-w><C-l>

nnoremap ss :%s//g<left><left>

nnoremap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<CR>

" Colorscheme
colorscheme palenight

" Highlight colors
highlight Comment gui=italic cterm=italic
highlight Normal guibg=NONE ctermbg=NONE
highlight visual guifg=#ffffff guibg=#7aa6da ctermbg=white ctermfg=Blue
highlight ErrorMsg ctermfg=224 ctermbg=NONE

" Lightline
let g:lightline = {
      \ 'colorscheme': 'greyscale',
      \ 'active': {
      \   'left': [ ['mode'], ['filename', 'modified', 'readonly'] ],
      \   'right': [ ['percent'] ]
      \ }
      \ }

" LaTeX
autocmd FileType tex setlocal shiftwidth=2
autocmd FileType tex inoremap <buffer> <C-t> <esc>:!pdflatex %:p<CR>a
autocmd FileType tex nnoremap <buffer> <C-t> :!pdflatex %:p<CR>

" ConTeXt
autocmd FileType context setlocal shiftwidth=2
autocmd FileType context inoremap <buffer> <C-t> <esc>:ConTeXt<CR>a
autocmd FileType context nnoremap <buffer> <C-t> :ConTeXt<CR>

" Yaml
autocmd FileType yaml setlocal shiftwidth=2

" Css
autocmd FileType css setlocal shiftwidth=2

" Disable auto-comments on new line
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Remove trailing whitespace when saving
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
