" NVIM
" 1. vim look into autogroups and ftplugin files
" 2. silence compile command for latex and context
" 3. switch buffer with fzf bound to C-e

" FIREFOX
" 1. firefox fix navbar and megabar

" OTHER
" TODO 0. fix fd-fzf situation: ask fd not to append full path when using . ~
" 1. remove divider from dock
" TODO 2. drobox share refactor push script
" 3. refactor zshrc
" TODO 4. fd don't ignore ubersicht widgets
" 5. refactor lf
" 6. look into mpv enhancements or remove directory if nothing interesting
" 7. maybe refactor nvim files
" 8. ask for app dependent bindings for skhd
" 9. put digital colour meter in top-right corner
" 10. yabai put rules for macOS programs in a loop that goes through every pre-installed program
" 11. refactor zsh
" 12. refactor Fonts, Themes, Wallpapers folders in Dropbox

" TO CREATE
" 1. uebersicht bar
" 2. finances web frontend
" 3. journaling setup
" 4. bootstrapping script
" 5. remake ndiet

" Plugs
call plug#begin('~/.config/nvim/plugged')
  " functionality
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'junegunn/fzf'
  Plug 'junegunn/goyo.vim'
  Plug 'farmergreg/vim-lastplace'
  Plug 'jiangmiao/auto-pairs'
  Plug 'Yggdroot/indentLine'
  " colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" Colorscheme
colorscheme onedark

" Sets
set splitright splitbelow
set number relativenumber
set shiftwidth=4
set tabstop=4
set expandtab                " expand tabs to spaces
set clipboard+=unnamedplus   " use the system clipboard
set termguicolors            " use 24-bit colors
set noshowmode               " hide the current mode
set undofile                 " remember undo history across sessions
set laststatus=0             " hide the status line
set autochdir                " set the pwd to the directory containing the file
set makeef=/var/tmp/ef##     " name of the errorfile for the ':make' command

" Lets
let mapleader=","
let maplocalleader=","
let g:netrw_home=$HOME.'/.cache/nvim'
let g:tex_conceal=''
let g:is_posix=1

" Maps
map  <C-a> ^
imap <C-a> <esc>^i
map  <C-e> $
imap <C-e> <esc>$a

map  <silent> <C-s> :w<cr>
imap <silent> <C-s> <esc>:w<cr>a
map  <silent> <C-w> :q<cr>
imap <silent> <C-w> <esc>:q<cr>

noremap <leader>w <C-w><C-k>
noremap <leader>a <C-w><C-h>
noremap <leader>s <C-w><C-j>
noremap <leader>d <C-w><C-l>

nmap ss :%s//g<left><left>
nmap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<cr>

" fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <c-u>undo<CR>

map <silent> <C-x><C-e> :FZF --prompt=>\ <cr>
imap <silent> <C-x><C-e> <esc>:FZF --prompt=>\ <cr>

" Highlights
highlight Normal guibg=NONE ctermbg=NONE
highlight Visual guibg=#7aa6da guifg=#ffffff ctermbg=blue ctermfg=white
highlight Comment gui=italic cterm=italic

highlight TabLineSel guibg=#626262 guifg=#ebebeb
highlight TabLine guibg=#393939 guifg=#b6b6b6
highlight TabLineFill guibg=NONE guifg=NONE

highlight VertSplit guibg=#5C6370 guifg=NONE
highlight StatusLine guibg=#5C6370 guifg=NONE
highlight StatusLineNC guibg=#5C6370 guifg=NONE

" Change vertical split character to a space
set fillchars=vert:\  "

" Autocmds
autocmd FileType    * setlocal formatoptions-=cro
autocmd BufWritePre * call StripTrailingWhitespaces()
autocmd InsertEnter * norm zz

" indentLine
let g:indentLine_char='│'
let g:indentLine_first_char='│'
let g:indentLine_showFirstIndentLevel=1
let g:indentLine_fileTypeExclude=['text', 'man']
let g:indentLine_defaultGroup='Comment'

" fzf
let g:fzf_layout={ 'window': { 'width': 0.7, 'height': 0.7, 'highlight': 'Normal', 'border': 'sharp' } }

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let [_, line, col, _, _] = getcurpos()
  %s/\s\+$//e
  call cursor(line, col)
endfunction
