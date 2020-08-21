" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
  " Plug 'jiangmiao/auto-pairs'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'morhetz/gruvbox'
  Plug 'Yggdroot/indentLine'
  Plug 'cohama/lexima.vim'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'joshdick/onedark.vim'
  Plug 'SirVer/ultisnips'
  Plug 'pacha/vem-tabline'
  Plug 'tpope/vim-commentary'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'tpope/vim-endwise'
  Plug 'farmergreg/vim-lastplace'
  Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-scriptease'
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
set laststatus=0
set noshowmode
set scrolloff=1
set termguicolors
set undofile

" }}}

" Plugin settings {{{

" CoC {{{

" Extensions to install if not already installed
let g:coc_global_extensions = [
  \ 'coc-python',
  \ 'coc-vimlsp',
  \ 'coc-vimtex',
  \ ]

" Check out this section of the wiki for more infos on completion sources
"   https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#completion-sources
let g:coc_sources_disable_map = {
  \ 'conf': ['around', 'buffer'],
  \ 'context': ['around', 'buffer'],
  \ 'markdown': ['around', 'buffer'],
  \ 'tex': ['around', 'buffer'],
  \ 'text': ['around', 'buffer'],
  \ 'vim': ['around', 'buffer'],
  \ 'yaml': ['around', 'buffer'],
  \ 'zsh': ['around', 'buffer'],
  \ }

" }}}

" colorizer.lua {{{

lua require'colorizer'.setup()

" }}}

" fzf {{{

let g:fzf_layout = {
  \ 'window': { 'width': 0.6, 'height': 0.6, 'highlight': 'Normal', 'border': 'sharp' }
  \ }

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

" Options for the ToC window
let g:vimtex_toc_show_preamble = 0
let g:vimtex_toc_config = {
  \ 'indent_levels': 1,
  \ 'layers' : ['content', 'include'],
  \ 'show_help': 0,
  \ 'split_pos': 'vert rightbelow',
  \ 'tocdepth': 6,
  \ }

" }}}

" }}}

" Assign variables {{{

" Leader keys
let mapleader = ','
let maplocalleader = ','

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

" Mappings {{{

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

iabbrev ‘ ‘’<Left>

" Navigate wrapped lines
" nmap <Up> gk
" nmap <Down> gj
" These following two don't play nicely with coc menus, probably need a <expr>
" mapping if I want to use them.
" imap <Up> <C-o>gk
" imap <Down> <C-o>gj

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
nmap <silent> <Leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<CR>

" Fix for https://github.com/neovim/neovim/issues/11393
cnoremap 3636 <C-u>undo<CR>

" fzf
map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>

" Cycle through and delete buffers
nmap <Tab> <Plug>vem_next_buffer-
nmap <silent> <Leader>x :call DeleteCurrentBuffer()<CR>

function! DeleteCurrentBuffer() abort
  let current_buffer = bufnr('%')
  let next_buffer = g:vem_tabline#tabline.get_replacement_buffer()
  try
    exec 'confirm ' . current_buffer . 'bdelete'
    if next_buffer != 0
      exec next_buffer . 'buffer'
    endif
  catch /E516:/
    " If the operation is cancelled, do nothing
  endtry
endfunction

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
  " autocmd BufRead *.tex call tex#PdfOpen()
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

" Colorscheme {{{

" Has to be after highlight_group augroup definition
colorscheme onedark

" }}}

" vim: set foldmethod=marker:
