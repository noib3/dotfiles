" Filename:   nvim/init.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
  " Functionality
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'junegunn/goyo.vim'
  Plug 'Yggdroot/indentLine'
  Plug 'SirVer/ultisnips'
  Plug 'easymotion/vim-easymotion'
  Plug 'farmergreg/vim-lastplace'
  Plug 'romainl/vim-cool'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'lervag/vimtex'
  " Colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" }}}

" Plugin settings {{{

" CoC {{{

" Extensions to install if not already installed
let g:coc_global_extensions = [
  \ 'coc-pairs',
  \ 'coc-python',
  \ 'coc-vimtex',
  \ ]

" Check out this section of the wiki for more infos on completion sources
"   https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#completion-sources
let g:coc_sources_disable_map = {
  \ 'conf': ['around', 'buffer'],
  \ 'markdown': ['around', 'buffer'],
  \ 'tex': ['around', 'buffer'],
  \ 'text': ['around', 'buffer'],
  \ 'vim': ['around', 'buffer'],
  \ 'zsh': ['around', 'buffer'],
  \ }

" }}}

" fzf {{{

let g:fzf_layout = {
  \ 'window': { 'width': 0.6, 'height': 0.6, 'highlight': 'Normal', 'border': 'sharp' }
  \ }

" }}}

" Goyo {{{

" let g:goyo_width = '65%'
" let g:goyo_height = '75%'

function! s:goyo_enter()
  " This should match the terminal background color
  " hi EndOfBuffer guifg=#282a36
  call EnterFullscreen()
endfunction

function! s:goyo_leave()
  " Color of the EndOfBuffer highlight group defined by the onedark colorscheme
  " hi EndOfBuffer guifg=#3b4048
  call ExitFullscreen()
endfunction

function! EnterFullscreen()
  if json_decode(systemlist('yabai -m query --windows --window'))['native-fullscreen'] == 0
    execute 'silent !yabai -m window --toggle native-fullscreen'
  endif
endfunction

function! ExitFullscreen()
  if json_decode(systemlist('yabai -m query --windows --window'))['native-fullscreen'] == 1
    execute 'silent !yabai -m window --toggle native-fullscreen'
  endif
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

" }}}

" indentLine {{{

let g:indentLine_char = '│'
let g:indentLine_first_char = '│'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_fileTypeExclude = ['text', 'man', 'conf']
let g:indentLine_defaultGroup = 'Comment'

" }}}

" UltiSnips {{{

let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
let g:UltiSnipsSnippetDirectories = ['UltiSnips']

" }}}

" vimtex {{{

" Disable the compiler and viewer interfaces
let g:vimtex_compiler_enabled = 0
let g:vimtex_view_enabled = 0

" Don't show the help text and bump up max depth to 6
let g:vimtex_toc_config = {
  \ 'show_help': 0,
  \ 'tocdepth': 6,
  \ }

" }}}

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
set foldtext=MarkerFoldsText()
set foldlevel=0
set foldlevelstart=0
set fillchars=fold:\ "

" Fold text for marker folds
function! MarkerFoldsText()
  let comment_char = substitute(&commentstring, '\s*%s', '', '')
  " The first substitute extracts the text between the commentstring and the
  " markers without leading spaces, the second one removes trailing spaces. It
  " could probably be done with a single substitute but idk how.
  let fold_title = substitute(getline(v:foldstart), comment_char.'\s*\(.*\){\{3}', '\1', '')
  let fold_title = substitute(fold_title, '\s*$', '', '')
  let dashes = repeat(v:folddashes, 2)
  let fold_size = v:foldend - v:foldstart + 1

  let fill_num = 68 - len(dashes . fold_title . fold_size)

  return '+' . dashes . ' ' . fold_title . ' ' . repeat('·', fill_num)
          \ . ' ' . fold_size . ' lines'
endfunction

" Miscellaneous
set termguicolors
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
let mapleader = ','
let maplocalleader = ','

" Home directory for bookmarks and history
let g:netrw_home = $HOME . '/.cache/nvim'

" Set default file type to LaTeX for .tex files
let g:tex_flavor = 'latex'

" Disable conceal feature for TeX documents
let g:tex_conceal = ''

" Default sh syntax-highlighting to be POSIX
let g:is_posix = 1

" }}}

" Key mappings {{{

" Go to beginning/end of line
map <C-a> ^
cmap <C-a> <C-b>
map <C-e> $
imap <C-a> <C-o>I
imap <C-e> <C-o>A

" Save and quit
map <silent> <C-s> :w<CR>
map <silent> <C-w> :q<CR>
imap <silent> <C-s> <C-o>:w<CR>
imap <silent> <C-w> <C-o>:q<CR>

" Replace string globally
nmap ss :%s//g<Left><Left>

" Toggle folds with space
nnoremap <Space> za

" Navigate splits
nnoremap <Leader>w <C-w>k
nnoremap <Leader>a <C-w>h
nnoremap <Leader>s <C-w>j
nnoremap <Leader>d <C-w>l

" Toggle 80 and 100 characters columns
nmap <silent> <Leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<CR>

" Fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <C-u>undo<CR>

" Plugin mappings {{{

" fzf
map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>

" Goyo
nmap <silent> <Leader>g :Goyo<CR>

" EasyMotion
nmap f <Plug>(easymotion-overwin-w)
nmap l <Plug>(easymotion-overwin-line)

" }}}

" }}}

" Autocommands {{{

" Autocommands for all file types
augroup all_group
  autocmd!
  autocmd FileType * setlocal formatoptions-=cro
  autocmd BufWritePre * call StripTrailingWhitespaces()
  autocmd InsertEnter * norm zz
augroup END

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let [_, line, col, _] = getpos('.')
  %s/\s\+$//e
  call cursor(line, col)
endfunction

" Autocommands for TeX related files
augroup tex_group
  autocmd!
  " autocmd BufRead *.tex call tex#PdfOpen()
  autocmd BufUnload *.tex call tex#PdfClose(expand('<afile>:p:r') . '.pdf',
                                            \ expand('<afile>:t:r') . '.pdf')
  autocmd BufRead *.sty set syntax=tex
  autocmd BufRead *.cls set syntax=tex
augroup END

" Autocommands to set/override some highlight groups
augroup highlight_group
  autocmd!
  autocmd ColorScheme * hi Normal guibg=NONE
  autocmd ColorScheme * hi Comment gui=italic
  autocmd ColorScheme * hi Visual guibg=#7aa6da guifg=#ffffff
  autocmd ColorScheme * hi VertSplit guibg=#5c6370 guifg=NONE
augroup END

" }}}

" Colorscheme {{{

" Has to be after highlight_group augroup definition
colorscheme onedark

" }}}
