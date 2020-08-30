" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
  Plug 'jiangmiao/auto-pairs'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'morhetz/gruvbox'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'joshdick/onedark.vim'
  Plug 'SirVer/ultisnips'
  Plug 'pacha/vem-tabline'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'lervag/vimtex'
call plug#end()

" }}}

" Nvim settings {{{

" Line numbering
set number
set relativenumber

" Window splitting
set splitright
set splitbelow

" Pattern searching
set ignorecase
set smartcase

" Line breaking
set linebreak
set textwidth=79
let &showbreak="\u21aa "

" Code folding
set foldlevelstart=0
let &fillchars='fold: '

" Miscellaneous
set autochdir
set clipboard+=unnamedplus
set expandtab
set hidden
set iskeyword-=_
set laststatus=0
set noshowmode
set scrolloff=1
set termguicolors
set undofile

" }}}

" Nvim mappings {{{

" Leader keys
let mapleader = ','
let maplocalleader = ','

" Go to beginning/end of line
map <C-a> ^
cmap <C-a> <C-b>
imap <C-a> <C-o>I
map <C-e> $
imap <C-e> <C-o>A

" Save and quit
map <silent> <C-s> :w<CR>
imap <silent> <C-s> <C-o>:w<CR>
map <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                          \ ':q<CR>' :
                          \ '<Plug>vem_delete_buffer-'
imap <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                           \ '<C-o>:q<CR>' :
                           \ '<C-o><Plug>vem_delete_buffer-'

" Navigate wrapped lines
nmap <Up> gk
nmap <Down> gj
imap <expr> <Up> pumvisible() == 0 ? '<C-o>gk' : '<Up>'
imap <expr> <Down> pumvisible() == 0 ? '<C-o>gj' : '<Down>'

" Replace string globally
nmap ss :%s//g<Left><Left>

" Toggle folds with space
nmap <Space> za

" Navigate splits
nnoremap <Leader>w <C-w>k
nnoremap <Leader>a <C-w>h
nnoremap <Leader>s <C-w>j
nnoremap <Leader>d <C-w>l

" Toggle 80 and 100 characters columns
nmap <silent> <Leader>c :execute 'set cc=' . (&cc == '' ? '80,100' : '')<CR>

" Fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <C-u>undo<CR>

" }}}

" Plugin settings and mappings {{{

" CoC {{{

" Extensions to install if not already installed
let g:coc_global_extensions = [
  \ 'coc-css',
  \ 'coc-json',
  \ 'coc-python',
  \ 'coc-vimlsp',
  \ 'coc-vimtex',
  \ ]

" Check out this section of the wiki for more infos on completion sources
"   https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#completion-sources
let g:coc_sources_disable_map = {
  \ 'conf': ['around', 'buffer'],
  \ 'context': ['around', 'buffer'],
  \ 'css': ['around', 'buffer'],
  \ 'markdown': ['around', 'buffer'],
  \ 'tex': ['around', 'buffer'],
  \ 'text': ['around', 'buffer'],
  \ 'vim': ['around', 'buffer'],
  \ 'yaml': ['around', 'buffer'],
  \ 'zsh': ['around', 'buffer'],
  \ }

" }}}

" colorizer.lua {{{

lua require 'colorizer'.setup({'*'}, {names = false})

" }}}

" Floaterm {{{

let g:floaterm_title = ''
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_autoclose = 2

nmap <silent> <Leader>l :FloatermNew lf<CR>

command! Py3 FloatermNew python3

" }}}

" fzf {{{

let g:fzf_layout = {
  \ 'window': { 'width': 0.6, 'height': 0.6, 'highlight': 'Normal', 'border': 'sharp' }
  \ }

map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>

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

" Vem Tabline {{{

nmap <Tab> <Plug>vem_next_buffer-

" }}}

" vimtex {{{

" Disable all insert mode mappings
let g:vimtex_imaps_enabled = 0

" Disable the compiler and viewer interfaces
let g:vimtex_compiler_enabled = 0
let g:vimtex_view_enabled = 0

" Options for the ToC window
let g:vimtex_toc_show_preamble = 0
let g:vimtex_toc_config = {
  \ 'indent_levels': 1,
  \ 'layers' : ['content', 'include'],
  \ 'show_help': 0,
  \ 'split_width' : 40,
  \ 'tocdepth': 6,
  \ }

" }}}

" }}}

" Autogroups {{{

" Autocommands for all file types
augroup all
  autocmd!
  autocmd InsertEnter * norm zz
  autocmd BufWritePre * let curr_pos = getpos('.')
                        \ | %s/\s\+$//e
                        \ | call setpos ('.', curr_pos)
augroup END

" Autocommands for TeX related files
augroup tex
  autocmd!
  autocmd BufRead *.sty setlocal syntax=tex
  autocmd BufRead *.cls setlocal syntax=tex
  autocmd BufRead *.tex call tex#PdfOpen()
  autocmd BufUnload *.tex call tex#PdfClose(expand('<afile>:p:r') . '.pdf',
                                            \ expand('<afile>:t:r') . '.pdf')
  autocmd User VimtexEventTocActivated norm zt
augroup END

" Autocommands to set/override some highlight groups
augroup highlights
  autocmd!
  autocmd ColorScheme * hi Normal guibg=NONE
  autocmd ColorScheme * hi Comment gui=italic
  autocmd ColorScheme * hi Visual guibg=#7aa6da guifg=#ffffff
  autocmd ColorScheme * hi VertSplit guibg=#5c6370 guifg=NONE
augroup END

" }}}

" Global variables {{{

" Home directory for bookmarks and history
let g:netrw_home = $HOME . '/.cache/nvim'

" Set default .tex's files filetype to LaTeX
let g:tex_flavor = 'latex'

" Disable conceal across multiple filetypes
let g:tex_conceal = ''
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_json_syntax_conceal = 0

" Set default shell syntax highlighting to POSIX
let g:is_posix = 1

" }}}

" Colorscheme {{{

" Has to be after the highlights augroup definition
colorscheme onedark

" }}}

" vim: foldmethod=marker
