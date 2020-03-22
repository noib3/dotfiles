" --------------------------- NEOVIM CONFIG FILE ----------------------------

" ---------------------------------------------------------------------------
" Plugins

call plug#begin('~/.config/nvim/plugged')
Plug 'jiangmiao/auto-pairs'
Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'
Plug 'terryma/vim-smooth-scroll'
Plug 'tpope/vim-surround'
call plug#end()

" ---------------------------------------------------------------------------
" Basic settings

set tabstop=4
set shiftwidth=4
set expandtab
set number
set relativenumber
set noshowmode
set clipboard+=unnamedplus
set fileencoding=utf-8

" ---------------------------------------------------------------------------
" Lets

let mapleader=","
let g:is_posix=1

" ---------------------------------------------------------------------------
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

nnoremap <C-g> g<C-g>

nnoremap ss :%s//g<left><left>

nnoremap <silent> <C-u> :call smooth_scroll#up(10, 10, 1)<cr>
nnoremap <silent> <C-d> :call smooth_scroll#down(10, 10, 1)<cr>

nnoremap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<CR>

" ---------------------------------------------------------------------------
" Colorscheme

colorscheme gruvbox

" Highlight colors
highlight Comment cterm=italic
highlight Normal ctermbg=NONE
highlight visual ctermbg=white ctermfg=Blue
highlight ErrorMsg ctermfg=224 ctermbg=NONE

" ---------------------------------------------------------------------------
" Lightline

let g:lightline = {
      \ 'colorscheme': 'greyscale',
      \ 'active': {
      \   'left': [ ['mode'], ['filename', 'modified', 'readonly'] ],
      \   'right': [ ['percent'] ]
      \ }
      \ }

" ---------------------------------------------------------------------------
" FileType-specific settings

" LaTeX
autocmd FileType tex setlocal shiftwidth=2

" Markdown
let g:pandoc#folding#fdc = 0
autocmd FileType rmd nnoremap <buffer> <C-r> :RMarkdown pdf<cr>
autocmd FileType rmd inoremap <buffer> <C-r> <esc>:RMarkdown pdf<cr>a
autocmd FileType rmd setlocal nospell
autocmd FileType rmd setlocal shiftwidth=2

" Yaml
autocmd FileType yaml setlocal shiftwidth=2

" Css
autocmd FileType css setlocal shiftwidth=2

" ---------------------------------------------------------------------------
" Misc

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
