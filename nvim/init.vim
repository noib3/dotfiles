" ----------------------- NEOVIM CONFIG FILE ------------------------

" Plugs
call plug#begin('~/.config/nvim/plugged')
  " functionality
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'farmergreg/vim-lastplace'
  Plug 'jiangmiao/auto-pairs'
  Plug 'itchyny/lightline.vim'
  " colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'icymind/NeoSolarized'
  Plug 'drewtempelmeyer/palenight.vim'
call plug#end()

" Sets
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
let g:netrw_home=$HOME.'/.cache/nvim'
let mapleader=","
let maplocalleader=","
let g:is_posix=1

" Maps
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
nnoremap <leader>r :so ~/.config/nvim/init.vim | echomsg 'ciao'<CR>
nnoremap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<CR>
nnoremap ss :%s//g<left><left>

" Colorscheme
" colorscheme gruvbox
" colorscheme NeoSolarized
colorscheme palenight

" Highlights
highlight normal guibg=NONE ctermbg=NONE
highlight visual guibg=#7aa6da guifg=#ffffff ctermbg=blue ctermfg=white
highlight comment gui=italic cterm=italic

" Status line
let g:lightline = {
      \ 'colorscheme': 'greyscale',
      \ 'active': {
      \   'left': [ ['mode'], ['filename', 'modified', 'readonly'] ],
      \   'right': [ ['filetype', 'percent'] ]
      \ }
      \ }

" Autocmds
autocmd FileType * setlocal formatoptions-=cro
autocmd FileType tex,context,vim,css,yaml setlocal shiftwidth=2
autocmd FileType tex,context inoremap <buffer> <silent> <C-t> <esc>:call TeXCompile()<CR>a
autocmd FileType tex,context nnoremap <buffer> <silent> <C-t> :call TeXCompile()<CR>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<CR>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<CR>
autocmd InsertEnter * norm zz
autocmd BufWritePre * :call StripTrailingWhitespaces()
autocmd BufReadPost *.tex :call PdfOpen()
autocmd BufUnload   *.tex :call PdfClose()

" Remove trailing whitespace without changing cursor positio
function! StripTrailingWhitespaces()
  let l = line(".")
  let c = col(".")
  %s/\s\+$//e
  call cursor(l, c)
endfunction

" Compile a TeX document
function! TeXCompile()
  let filename = expand('%:p')
  execute '!cd $(dirname' shellescape(filename, 1).') && pdflatex -synctex=1' shellescape(filename, 1)
endfunction

" Open the PDF file created by a TeX document
function! PdfOpen()
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
function! PdfClose()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
      "execute 'silent !touch /Users/noibe/ciao'
  endif
endfunction

" Use SyncTex to jump from a line in a TeX document to its PDF output
function! SyncTeXForwardSearch()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    execute 'silent !/Applications/Skim.app/Contents/SharedSupport/displayline' line('.') shellescape(filename, 1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filename.'"'
    echohl None
  endif
endfunction
