" ----------------------- NEOVIM CONFIG FILE ------------------------

" Plugins
call plug#begin('~/.config/nvim/plugged')
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'itchyny/lightline.vim'
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

" Remove trailing whitespace when saving
function! StripTrailingWhitespaces()
  let l = line(".")
  let c = col(".")
  %s/\s\+$//e
  call cursor(l, c)
endfunction
autocmd BufWritePre * :call StripTrailingWhitespaces()

" Open the PDF file created by a TeX document
function! OpenPDF()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    execute 'silent !open' shellescape(filename, 1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filename.'"'
    echohl None
  endif
endfunction

" Close the PDF file created by a TeX document
function! ClosePDF()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
      "execute 'silent !touch /Users/noibe/ciao'
  endif
endfunction

" Use SyncTex to jump from a line in a TeX document to its PDF output
function! ForwardSyncTeXSearch()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    execute 'silent !/Applications/Skim.app/Contents/SharedSupport/displayline' line('.') shellescape(filename, 1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filename.'"'
    echohl None
  endif
endfunction

" Set shorter shiftwidths for some filetypes
autocmd FileType tex,context,yaml,css setlocal shiftwidth=2

" LaTeX
autocmd FileType tex inoremap <buffer> <C-t> <esc>:!cd $(dirname "%:p") && pdflatex -synctex=1 "%:p"<CR>a
autocmd FileType tex nnoremap <buffer> <C-t> :!cd $(dirname "%:p") && pdflatex -synctex=1 "%:p"<CR>
autocmd FileType tex nnoremap <buffer> <silent> <leader>p :call OpenPDF()<CR>
autocmd FileType tex nnoremap <buffer> <silent> <leader>f :call ForwardSyncTeXSearch()<CR>
autocmd BufReadPost *.tex :call OpenPDF()
autocmd BufUnload *.tex :call ClosePDF()

" ConTeXt
autocmd FileType context inoremap <buffer> <C-t> <esc>:ConTeXt<CR>a
autocmd FileType context nnoremap <buffer> <C-t> :ConTeXt<CR>
autocmd FileType context nnoremap <buffer> <silent> <leader>p :call OpenPDF()<CR>
autocmd FileType context nnoremap <buffer> <silent> <leader>f :call ForwardSyncTeXSearch()<CR>
