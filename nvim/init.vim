" ----------------------- NEOVIM CONFIG FILE ------------------------

" Plugins
call plug#begin('~/.config/nvim/plugged')
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'itchyny/lightline.vim'
  Plug 'chrisbra/Colorizer'
  Plug 'farmergreg/vim-lastplace'
  Plug 'jiangmiao/auto-pairs'
  Plug 'drewtempelmeyer/palenight.vim'
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
set termguicolors
set undofile
set undodir=$HOME/.cache/nvim
set undolevels=1000
set undoreload=10000

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

" Vertically center document when entering insert mode
autocmd InsertEnter * norm zz

" Disable auto-comments on new line
autocmd FileType * setlocal formatoptions-=cro

" Lightline
let g:lightline = {
      \ 'colorscheme': 'greyscale',
      \ 'active': {
      \   'left': [ ['mode'], ['filename', 'modified', 'readonly'] ],
      \   'right': [ ['percent'] ]
      \ }
      \ }

" Colorizer
let g:colorizer_auto_color=1

" Remove trailing whitespace when saving
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()

" LaTeX
autocmd FileType tex setlocal shiftwidth=2
autocmd FileType tex inoremap <buffer> <C-t>
                 \ <esc>:!cd $(dirname "%:p") && pdflatex "%:p"<CR>a
autocmd FileType tex nnoremap <buffer> <C-t>
                 \ :!cd $(dirname "%:p") && pdflatex "%:p"<CR>
"autocmd FileType tex nnoremap <buffer> <leader>p
"                 \ :silent !open $(echo "%:p" \| sed s/.tex/.pdf/g)<CR>
autocmd FileType tex nnoremap <leader>p
                 \ :execute 'silent !open $(echo "%:p" \| sed s/.tex/.pdf/g)'<CR>
                 "\ :execute 'silent !open $(echo "%:p" \| sed s/.tex/.pdf/g)' | redraw!<CR>
                 "\ :silent !open $(echo "%:p" \| sed s/.tex/.pdf/g)<CR>
autocmd BufReadPost *.tex :silent !open $(echo "%:p" \| sed s/.tex/.pdf/g)

" ConTeXt
autocmd FileType context setlocal shiftwidth=2
autocmd FileType context inoremap <buffer> <C-t> <esc>:ConTeXt<CR>a
autocmd FileType context nnoremap <buffer> <C-t> :ConTeXt<CR>
autocmd FileType context nnoremap <buffer> <leader>p
                 \ :!open $(echo "%:p" \| sed s/.tex/.pdf/g)<CR>

" Yaml
autocmd FileType yaml setlocal shiftwidth=2

" Css
autocmd FileType css setlocal shiftwidth=2

" Tex forward search for the Skim pdf viewer
" https://sourceforge.net/p/skim-app/wiki/TeX_and_PDF_Synchronization/#tex-pdf-synchronization
map <leader>f :w<CR>:silent !/Applications/Skim.app/Contents/SharedSupport/displayline <C-r>=line('.')<CR> %<.pdf<CR>
