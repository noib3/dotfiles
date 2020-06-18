" NEOVIM
" 1. vim look into autogroups and ftplugin files
" 2. silence compile command for latex and content
" 3. tex file closes other pdfs not only his own fix that
" 4. undo should go back to last change not to last save

" FIREFOX
" 1. firefox fix navbar and megabar

" OTHER
" TODO 1. understand why sometimes when it's launched with fzf_opener it looks fucked up
" 2. fzf launcher support for multiple files
" 3. fix all skhd yabai bindings, for ex alt+w with a program on space 3 but spawned from space 2 puts it on space 1
" 4. remove divider from dock

" TO CREATE
" 1. refactor committed script, calcurse.pid doesn't get pushed, I only try to commit if there is something to commit, option to clear the screen for every git folder
" 2. setup bar with uebersicht
" 3. refactor 2d2small and journal classes
" 4. make program to track time, a binding brings up a menu with the current tasks open, if you click on one it continues that task and tracks the time, binding to stop the task, data saved in json/yaml file, web frontend
" 5. finances web frontend
" 6. remake ndiet

" Plugs
call plug#begin('~/.config/nvim/plugged')
  " functionality
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'farmergreg/vim-lastplace'
  Plug 'jiangmiao/auto-pairs'
  Plug 'Yggdroot/indentLine'
  Plug 'junegunn/goyo.vim'
  " colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" Sets
" set splitright splitbelow
" set number relativenumber
" set shiftwidth=4
" set tabstop=4
" set expandtab                " expand tabs to spaces
" set clipboard+=unnamedplus   " use the system clipboard
" set termguicolors            " use 24-bit colors
" set noshowmode               " hide the current mode
" set undofile                 " remember undo history across sessions
" set laststatus=0             " hide the status line
" set autochdir                " set the pwd to the directory containing the file
" set makeef=/var/tmp/ef##     " name of the errorfile for the ':make' command

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

" Colorscheme
" colorscheme onedark

" " Highlights
" highlight Normal guibg=NONE ctermbg=NONE
" highlight Visual guibg=#7aa6da guifg=#ffffff ctermbg=blue ctermfg=white
" highlight Comment gui=italic cterm=italic

" highlight TabLineSel guibg=#626262 guifg=#ebebeb
" highlight TabLine guibg=#393939 guifg=#b6b6b6
" highlight TabLineFill guibg=NONE guifg=NONE

" highlight VertSplit guibg=#5C6370 guifg=NONE
" highlight StatusLine guibg=#5C6370 guifg=NONE
" highlight StatusLineNC guibg=#5C6370 guifg=NONE

" " Change vertical split character to a space
" set fillchars=vert:\  "

" " Autocmds
" autocmd FileType    * setlocal formatoptions-=cro
" autocmd BufWritePre * call StripTrailingWhitespaces()
" autocmd InsertEnter * norm zz

" " indentLine
" let g:indentLine_char='│'
" let g:indentLine_first_char='│'
" let g:indentLine_showFirstIndentLevel=1
" let g:indentLine_fileTypeExclude=['text']
" let g:indentLine_defaultGroup='Comment'

" " Remove trailing whitespace without changing cursor position
" function! StripTrailingWhitespaces()
"   let [_, line, col, _, _] = getcurpos()
"   execute printf('%d substitute/\%%%dc\s\+$//e', line, col+1)
"   execute printf('vglobal/\%%%dl/substitute/\s\+$//e', line)
"   call cursor(line, col)
" endfunction
