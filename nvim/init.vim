" Filename:   nvim/init.vim
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
  Plug 'SirVer/ultisnips'
  Plug 'farmergreg/vim-lastplace'
  Plug 'Yggdroot/indentLine'
  Plug 'jiangmiao/auto-pairs'
  " Colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" }}}

" Plugin settings: fzf {{{

let g:fzf_layout={ 'window': { 'width': 0.6, 'height': 0.6, 'highlight': 'Normal', 'border': 'sharp' } }

" }}}

" Plugin settings: Goyo {{{

let g:goyo_width = '65%'
let g:goyo_height = '75%'

function! s:goyo_enter()
  " This should match the terminal background color
  hi EndOfBuffer guifg=#282a36
  call EnterFullscreen()
endfunction

function! s:goyo_leave()
  " Color of the EndOfBuffer highlight group defined by the onedark colorscheme
  hi EndOfBuffer guifg=#3b4048
  call ExitFullscreen()
endfunction

function! EnterFullscreen()
  if json_decode(systemlist('yabai -m query --windows --window'))["native-fullscreen"] == 0
    execute "silent !yabai -m window --toggle native-fullscreen"
  endif
endfunction

function! ExitFullscreen()
  if json_decode(systemlist('yabai -m query --windows --window'))["native-fullscreen"] == 1
    execute "silent !yabai -m window --toggle native-fullscreen"
  endif
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

" }}}

" Plugin settings: UltiSnips {{{

let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
let g:UltiSnipsSnippetDirectories = ["UltiSnips"]

" }}}

" Plugin settings: indentLine {{{

let g:indentLine_char = '│'
let g:indentLine_first_char = '│'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_fileTypeExclude = ['text', 'man', 'conf']
let g:indentLine_defaultGroup = 'Comment'

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

" Pattern searching
set ignorecase
set smartcase

" Code folding
set foldmethod=marker
set foldlevel=0
set foldlevelstart=0
set fillchars=fold:\ "
set foldtext=MarkerFoldText()

" Fold text for marker folds
function! MarkerFoldText()
  let comment_char = substitute(&commentstring, '\s*%s', '', '')
  let fold_text = substitute(getline(v:foldstart), comment_char.' *\(.*\) {\{3}', '\1', '')
  let folded_lines = v:foldend - v:foldstart + 1
  let fillchars = 66 - len(fold_text) - len(folded_lines)
  return '+-- '.fold_text.' '.repeat('·', fillchars).' '.folded_lines.' lines'
endfunction

" Enable 24bit colors and set colorscheme
set termguicolors
colorscheme onedark

" Miscellaneous
set clipboard+=unnamedplus
set noshowmode
set undofile
set laststatus=0
set autochdir
set makeef=/tmp/nvim##.err
set hidden

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

" Toggle folds with space
nnoremap <Space> za

" Toggle Goyo
noremap <silent> <leader>g :Goyo<CR>

" Navigate splits
noremap <leader>w <C-w><C-k>
noremap <leader>a <C-w><C-h>
noremap <leader>s <C-w><C-j>
noremap <leader>d <C-w><C-l>

" Toggle 80 and 100 characters columns
nmap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<CR>

" Fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <c-u>undo<CR>

" }}}

" Variable assignments {{{

" Leader keys
let mapleader = ','
let maplocalleader = ','

" Home directory for bookmarks and history
let g:netrw_home = $HOME.'/.cache/nvim'

" Disable conceal feature for TeX documents
let g:tex_conceal = ''

" Default sh syntax-highlighting to be POSIX
let g:is_posix = 1

" }}}

" Autocommands {{{

"
augroup BaseGroup
  autocmd!
  autocmd FileType    * setlocal formatoptions-=cro
  autocmd BufWritePre * call StripTrailingWhitespaces()
  autocmd InsertEnter * norm zz
augroup END

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let [_, line, col, _] = getpos('.')
  %s/\s\+$//e
  call cursor(line, col)
endfunction

"
augroup TeXGroup
  autocmd!
  autocmd BufRead *.tex call tex#PDFOpen()
  autocmd BufUnload *.tex call tex#PDFClose(expand('<afile>:p:r').'.pdf', expand('<afile>:t:r').'.pdf')
  autocmd BufRead *.sty set syntax=tex
  autocmd BufRead *.cls set syntax=tex
augroup END

"
augroup Highlights
  autocmd!
  autocmd ColorScheme * hi Normal guibg=NONE
  autocmd ColorScheme * hi Comment gui=italic
  autocmd ColorScheme * hi Visual guibg=#7aa6da guifg=#ffffff
  autocmd ColorScheme * hi VertSplit guibg=#5c6370 guifg=NONE
augroup END

" }}}
