" Filename:   init.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
  " Functionality
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'junegunn/fzf'
  Plug 'junegunn/goyo.vim'
  Plug 'farmergreg/vim-lastplace'
  Plug 'jiangmiao/auto-pairs'
  Plug 'Yggdroot/indentLine'
  " Colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" }}}

" Plugin settings: fzf {{{

let g:fzf_layout={ 'window': { 'width': 0.7, 'height': 0.7, 'highlight': 'Normal', 'border': 'sharp' } }

" }}}

" Plugin settings: indentLine {{{

let g:indentLine_char='│'
let g:indentLine_first_char='│'
let g:indentLine_showFirstIndentLevel=1
let g:indentLine_fileTypeExclude=['text', 'man', 'conf']
let g:indentLine_defaultGroup='Comment'

" }}}

" Basic settings {{{

" Line numbering
set number
set relativenumber

" Tab handling
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Window splitting
set splitright
set splitbelow

" Code folding
set foldmethod=marker
set foldlevel=0
set foldlevelstart=0
set fillchars=fold:\ "
set foldtext=MarkerFoldText()

" Miscellaneous
set clipboard+=unnamedplus
set noshowmode
set undofile
set laststatus=0
set autochdir
set makeef=/tmp/nvim##.err
set hidden

" }}}

" Variable assignments {{{

" Leader keys
let mapleader=','
let maplocalleader=','

"
let g:netrw_home=$HOME.'/.cache/nvim'

"
let g:tex_conceal=''

"
let g:is_posix=1

" }}}

" Key mappings {{{

" Go to beginning/end of line
map  <C-a> ^
map  <C-e> $
imap <C-a> <esc>^i
imap <C-e> <esc>$a

" Save and quit
map  <silent> <C-s> :w<CR>
map  <silent> <C-w> :q<CR>
imap <silent> <C-s> <esc>:w<CR>a
imap <silent> <C-w> <esc>:q<CR>

" Replace string globally
nmap ss :%s//g<Left><Left>

" Open fzf window
map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
imap <silent> <C-x><C-e> <esc>:FZF --prompt=>\  ~<CR>

" Navigate splits
noremap <leader>w <C-w><C-k>
noremap <leader>a <C-w><C-h>
noremap <leader>s <C-w><C-j>
noremap <leader>d <C-w><C-l>

" Toggle 80 and 100 characters columns
nmap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<CR>

" Toggle folds with space
nnoremap <Space> za

" Fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <c-u>undo<CR>

" }}}

" Autocommands {{{

augroup BaseGroup
  autocmd!
  autocmd FileType    * setlocal formatoptions-=cro
  autocmd BufWritePre * call StripTrailingWhitespaces()
  autocmd InsertEnter * norm zz
augroup END

" Open the PDF file on entry and close it on exit
augroup TeXGroup
  autocmd!
  autocmd BufRead *.tex call tex#PDFOpen()
  autocmd BufUnload *.tex call tex#PDFClose()
augroup END

" }}}

" Functions {{{

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let [_, line, col, _, _] = getcurpos()
  %s/\s\+$//e
  call cursor(line, col)
endfunction

" Fold text by marker
function! MarkerFoldText()
  let comment_char = substitute(&commentstring, '\s*%s', '', '')
  let fold_text = substitute(getline(v:foldstart), comment_char.' *\(.*\) {\{3}', '\1', '')
  let folded_lines = v:foldend - v:foldstart + 1
  let fillchars = 66 - len(fold_text) - len(folded_lines)
  return '+-- '.fold_text.' '.repeat('·', fillchars).' '.folded_lines.' lines'
endfunction

" }}}

" Colors {{{

set termguicolors

" Colorscheme
colorscheme onedark

" Highlights
hi Normal guibg=NONE
hi Comment gui=italic
hi Visual guibg=#7aa6da guifg=#ffffff
hi VertSplit guibg=#5c6370 guifg=NONE

" }}}
