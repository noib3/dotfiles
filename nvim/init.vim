" Plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'jiangmiao/auto-pairs'
Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'shinchu/lightline-gruvbox.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'
Plug 'terryma/vim-smooth-scroll'
Plug 'connorholyday/vim-snazzy'
Plug 'tpope/vim-surround'
Plug 'lervag/vimtex'
call plug#end()

" Basics
set tabstop=4
set shiftwidth=4
set expandtab

set number
set relativenumber

set noshowmode
set noshowcmd

let mapleader = ","

" Mappings
nnoremap <C-s> :w<cr>
inoremap <C-s> <esc>:w<cr>a
nnoremap <C-w> :q<cr>
inoremap <C-w> <esc>:q<cr>

nnoremap <C-a> ^
inoremap <C-a> <esc>^i
nnoremap <C-e> g_
inoremap <C-e> <esc>g_a

nnoremap ss :%s//g<left><left>

nnoremap <silent> <C-u> :call smooth_scroll#up(20, 10, 2)<cr>
nnoremap <silent> <C-d> :call smooth_scroll#down(20, 10, 2)<cr>

nnoremap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<CR>

" Colorscheme
set background=dark
colorscheme gruvbox
" colorscheme snazzy
" let g:SnazzyTransparent = 1

" Highlight colors
highlight Comment cterm=italic
highlight Normal ctermbg=NONE
highlight ErrorMsg ctermfg=224 ctermbg=NONE

" Lightline
let g:lightline = {
      \ 'colorscheme': 'srcery_drk',
      \ 'active': {
      \   'left': [ ['mode', 'paste'],
      \             ['readonly', 'absolutepath', 'modified'] ],
      \   'right': [ ['lines'],
      \              ['fileencoding'],
      \              ['filetype'] ]
      \ },
      \ 'component': {
      \   'lines': '%LL',
      \ }
      \ }

" LaTeX
let g:vimtex_compiler_method='arara'
let g:vimtex_view_method='skim'
autocmd FileType tex nnoremap <buffer> <C-t> :VimtexCompile<cr>
autocmd FileType tex inoremap <buffer> <C-t> <esc>:VimtexCompile<cr>a

" Markdown
let g:pandoc#folding#fdc = 0
autocmd FileType rmd nnoremap <buffer> <C-t> :RMarkdown pdf<cr>
autocmd FileType rmd inoremap <buffer> <C-t> <esc>:RMarkdown pdf<cr>a
autocmd FileType rmd setlocal nospell
autocmd FileType rmd setlocal shiftwidth=2

" Yaml
autocmd FileType yaml setlocal shiftwidth=2

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
