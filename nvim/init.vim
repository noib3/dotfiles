" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
  Plug 'jiangmiao/auto-pairs'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'joshdick/onedark.vim'
  Plug 'SirVer/ultisnips'
  Plug 'pacha/vem-tabline'
  Plug 'danilo-augusto/vim-afterglow'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'kana/vim-textobj-user'
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

" Miscellaneous
set autochdir
set clipboard+=unnamedplus
set expandtab
let &fillchars='fold: '
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

" Save buffer
map <silent> <C-s> :w<CR>
imap <silent> <C-s> <C-o>:w<CR>

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
\   'coc-css',
\   'coc-json',
\   'coc-python',
\   'coc-vimlsp',
\   'coc-vimtex',
\ ]

" Check out this section of the wiki for more infos on completion sources
"   https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources#completion-sources
let g:coc_sources_disable_map = {
\   'conf': ['around', 'buffer'],
\   'context': ['around', 'buffer'],
\   'css': ['around', 'buffer'],
\   'markdown': ['around', 'buffer'],
\   'tex': ['around', 'buffer'],
\   'text': ['around', 'buffer'],
\   'vim': ['around', 'buffer'],
\   'yaml': ['around', 'buffer'],
\   'zsh': ['around', 'buffer'],
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
\   'window': { 'width': 0.6, 'height': 0.6, 'highlight': 'Normal', 'border': 'sharp' }
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

let g:vem_tabline_show_number = 'index'
let g:vem_tabline_number_symbol = ': '

" Switch to the i-th buffer with <Fi>, i = 1,...,9, only if there are at least
" i buffers open.
for i in range(1, 9)
  execute 'nmap <expr> <silent> <F' . i . '> '
          \ . "len(getbufinfo({'buflisted':1})) >= " . i . ' ?'
          \ . "':VemTablineGo " . i . "<CR>' :"
          \ . "''"
  execute 'imap <expr> <silent> <F' . i . '> '
          \ . "len(getbufinfo({'buflisted':1})) >= " . i . ' ?'
          \ . "'<C-o>:VemTablineGo " . i . "<CR>' :"
          \ . "''"
endfor

" If there are multiple buffers open close the current one, else quit neovim
map <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                          \ ':q<CR>' :
                          \ '<Plug>vem_delete_buffer-'
imap <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                           \ '<C-o>:q<CR>' :
                           \ '<C-o><Plug>vem_delete_buffer-'

" }}}

" vim-textobj-user {{{

call textobj#user#plugin('markdown', {
\   'asterisks-a': {
\     'pattern': '[\*][^$]*[\*]',
\     'select': [],
\   },
\   'asterisks-i': {
\     'pattern': '[\*]\zs[^$]*\ze[\*]',
\     'select': [],
\   },
\ })

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
\   'indent_levels': 1,
\   'layers' : ['content', 'include'],
\   'show_help': 0,
\   'split_width' : 40,
\   'tocdepth': 6,
\ }

" }}}

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

" Autogroups {{{

augroup all
  autocmd!
  autocmd BufWritePre * call StripTrailingWhiteSpace()
  autocmd BufLeave * call AutoSaveWinView()
  autocmd BufEnter * call AutoRestoreWinView()
  autocmd ColorScheme * hi Normal guibg=NONE
  autocmd ColorScheme * hi Comment gui=italic
augroup END

augroup tex
  autocmd!
  autocmd BufRead *.tex call tex#PdfOpen()
  autocmd BufUnload *.tex call tex#PdfClose(expand('<afile>:p:r') . '.pdf',
                                            \ expand('<afile>:t:r') . '.pdf')
  autocmd User VimtexEventTocActivated norm zt
  autocmd BufRead *.sty setlocal syntax=tex
  autocmd BufRead *.cls setlocal syntax=tex
augroup END

augroup markdown_textobjs
  autocmd!
  autocmd FileType markdown call textobj#user#map('markdown', {
  \   'asterisks-a': {
  \     'select': '<buffer> a*',
  \   },
  \   'asterisks-i': {
  \     'select': '<buffer> i*',
  \   },
  \ })
augroup END

" }}}

" Colorscheme {{{

augroup afterglow
  autocmd!
  autocmd ColorScheme * hi Visual guifg=#d6d6d6 guibg=#5a647e
  autocmd ColorScheme * hi VertSplit guifg=NONE guibg=#5a647e
  autocmd ColorScheme * hi VemTabLineNormal guifg=#a1a1a1 guibg=#393939
  autocmd ColorScheme * hi VemTabLineNumber guifg=#a1a1a1 guibg=#393939
  autocmd ColorScheme * hi VemTabLineSelected guifg=#d6d6d6 guibg=#797979 gui=NONE
  autocmd ColorScheme * hi VemTabLineNumberSelected guifg=#d6d6d6 guibg=#797979 gui=NONE
augroup END

colorscheme afterglow


" }}}

" Functions {{{

function! StripTrailingWhiteSpace()
  let curr_pos = getpos('.')
  %s/\s\+$//e
  call setpos ('.', curr_pos)
endfunction

" https://vim.fandom.com/wiki/Avoid_scrolling_when_switch_buffers {{{

" Save current view settings on a per-window, per-buffer basis.
function! AutoSaveWinView()
  if !exists("w:SavedBufView")
    let w:SavedBufView = {}
  endif
  let w:SavedBufView[bufnr("%")] = winsaveview()
endfunction

" Restore current view settings.
function! AutoRestoreWinView()
  let buf = bufnr("%")
  if exists("w:SavedBufView") && has_key(w:SavedBufView, buf)
    let v = winsaveview()
    let atStartOfFile = v.lnum == 1 && v.col == 0
    if atStartOfFile && !&diff
      call winrestview(w:SavedBufView[buf])
    endif
    unlet w:SavedBufView[buf]
  endif
endfunction

" }}}

" }}}

" vim: foldmethod=marker
