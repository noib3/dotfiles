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
Plug 'lervag/vimtex'
call plug#end()

" Basics
filetype on
filetype plugin indent on
syntax enable

set tabstop=4
set shiftwidth=4
set expandtab

set number
set relativenumber

set noshowmode

" Aliases
nnoremap <C-s> :w<cr>
inoremap <C-s> <esc>:w<cr>a
nnoremap <C-w> :q<cr>
inoremap <C-w> <esc>:q<cr>

nnoremap ss :%s//g<left><left>

nnoremap <silent> <C-u> :call smooth_scroll#up(20, 10, 2)<cr>
nnoremap <silent> <C-d> :call smooth_scroll#down(20, 10, 2)<cr>

" Colorscheme
set background=dark
colorscheme gruvbox

" Highlight colors
highlight Normal ctermbg=NONE
highlight ErrorMsg cterm=bold ctermfg=224 ctermbg=NONE
autocmd ColorScheme * highlight ExtraWhitespace guibg=#FFFFFF ctermbg=0

" Lightline
let g:lightline = {
      \ 'colorscheme': 'jellybeans',
      \ 'active': {
      \   'right': [ [ 'total_lines' ],
      \              [ 'lineinfo' ],
      \              [ 'filetype', 'fileencoding'] ]
      \ },
      \ 'component': {
      \   'total_lines': '%L'
      \ },
      \ 'component_function': {
      \   'filename': 'LightlineFilename'
      \ },
      \ }
function! LightlineFilename()
  return expand('%')
endfunction

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
autocmd FileType yml setlocal shiftwidth=2

" Disable auto-comments on new line
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Grey column at 80 chars
" let &colorcolumn=join(range(81,999),",")
" let &colorcolumn="80,".join(range(400,999),",")

" Remove trailing whitespace when saving
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd BufWritePre * :call <SID>StripTrailingWhitespaces()
