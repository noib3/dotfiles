" Plugins {{{

call plug#begin('~/.config/nvim/plugged')
 " Functionality
  Plug 'jiangmiao/auto-pairs'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf'
  Plug 'Yggdroot/indentLine'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'SirVer/ultisnips'
  Plug 'pacha/vem-tabline'
  Plug 'romainl/vim-cool'
  Plug 'ryanoasis/vim-devicons'
  Plug 'voldikss/vim-floaterm'
  Plug 'farmergreg/vim-lastplace'
  Plug 'embear/vim-localvimrc'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-scriptease'
  Plug 'tpope/vim-surround'
  Plug 'kana/vim-textobj-user'
  Plug 'lervag/vimtex'
  " Syntax
  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'elzr/vim-json'
  " Color schemes
  Plug 'joshdick/onedark.vim'
  Plug 'danilo-augusto/vim-afterglow'
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

" Show tab characters as ⇥
set list
set listchars=tab:\⇥\ ,

" Miscellaneous
set autochdir
set clipboard+=unnamedplus
set expandtab
let &fillchars='fold: ,vert: '
set hidden
set iskeyword-=_
set laststatus=0
set mouse=a
set noshowmode
set noswapfile
set scrolloff=1
set spellfile=~/Dropbox/share/nvim/spell/en.utf-8.add
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
nmap <silent> <Leader>c :execute 'setlocal cc=' . (&cc == '' ? '80,100' : '')<CR>

" }}}

" Plugin settings & mappings {{{

" CoC {{{

let g:coc_global_extensions = [
\   'coc-css',
\   'coc-json',
\   'coc-python',
\   'coc-vimlsp',
\   'coc-vimtex',
\ ]

" }}}

" colorizer.lua {{{

lua require 'colorizer'.setup({'*'}, {names = false})

" }}}

" Floaterm {{{

let g:floaterm_title = ''
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_autoclose = 2

nmap <silent> ll :FloatermNew lf<CR>
nmap <silent> <Leader>i :FloatermNew ipython<CR>
nmap <silent> <Leader>g :FloatermNew lazygit<CR>

" }}}

" fzf {{{

let g:fzf_layout = {
\   'window': { 'width': 1, 'height': 9, 'yoffset': 0,
\               'highlight': 'FzfBorder', 'border': 'bottom' }
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

" Localvimrc {{{

let g:localvimrc_file_directory_only = 1
let g:localvimrc_sandbox = 0
let g:localvimrc_ask = 0

" }}}

" UltiSnips {{{

let g:UltiSnipsExpandTrigger = '<Tab>'
let g:UltiSnipsJumpForwardTrigger = '<Tab>'
let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
let g:UltiSnipsSnippetDirectories = ['UltiSnips']

" }}}

" Vem Tabline {{{

let g:vem_tabline_show_number = 'index'
let g:vem_tabline_number_symbol = ': '

for i in range(1, 9)
  execute 'nmap <silent> <F' . i . '> :silent! VemTablineGo ' . i . '<CR>'
endfor

nmap <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                           \ ':q<CR>' :
                           \ '<Plug>vem_delete_buffer-'
imap <expr> <silent> <C-w> len(getbufinfo({'buflisted':1})) == 1 ?
                           \ '<C-o>:q<CR>' :
                           \ '<C-o><Plug>vem_delete_buffer-'

" }}}

" SnipMate {{{

let g:snipMate = {}
let g:snipMate.scope_aliases = {}
let g:snipMate.scope_aliases['tex'] = 'tex,plaintex'
let g:snipMate.scope_aliases['context'] = 'context,plaintex'
let g:snipMate.snippet_version = 1

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

let g:vimtex_compiler_enabled = 0
let g:vimtex_view_enabled = 0

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

if exists('python_highlight_all')
  unlet python_highlight_all
endif

if exists('python_space_error_highlight')
  unlet python_space_error_highlight
endif

" }}}

" Autogroups & functions {{{

augroup all
  autocmd!
  autocmd BufWritePre * call StripTrailingWhiteSpace()
  autocmd BufLeave * call AutoSaveWinView()
  autocmd BufEnter * call AutoRestoreWinView()
  autocmd ColorScheme * highlight Normal guibg=NONE
  autocmd ColorScheme * highlight Comment gui=italic
augroup END

augroup tex
  autocmd!
  autocmd BufRead *.tex call tex#PdfOpen()
  autocmd BufUnload *.tex call tex#PdfClose(expand('<afile>:p:r') . '.pdf',
                                            \ expand('<afile>:t:r') . '.pdf')
  autocmd BufRead *.cls setlocal filetype=tex
  autocmd ColorScheme * highlight texComment gui=italic
  autocmd User VimtexEventTocActivated norm zt
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

" Colorscheme {{{

augroup patch_colors
  autocmd!
  autocmd ColorScheme afterglow call s:patch_afterglow_colors()
augroup END

function! s:patch_afterglow_colors()
  let g:terminal_color_0 = '#1a1a1a'
  let g:terminal_color_1 = '#ac4142'
  let g:terminal_color_2 = '#b4c973'
  let g:terminal_color_3 = '#e5b567'
  let g:terminal_color_4 = '#6c99bb'
  let g:terminal_color_5 = '#b05279'
  let g:terminal_color_6 = '#9e86c8'
  let g:terminal_color_7 = '#d6d6d6'
  highlight Visual guifg=#d6d6d6 guibg=#5a647e
  highlight VertSplit guifg=NONE guibg=#5a647e
  highlight SpellBad guifg=#ac4142 gui=underline
  highlight SpellCap guifg=#e87d3e gui=NONE
  highlight htmlItalic guifg=#9e86c8 gui=italic
  highlight htmlBold guifg=#e87d3e gui=bold
  highlight VemTabLineNormal guifg=#a1a1a1 guibg=#393939
  highlight VemTabLineLocation guifg=#a1a1a1 guibg=#393939
  highlight VemTabLineNumber guifg=#a1a1a1 guibg=#393939
  highlight VemTabLineSelected guifg=#d6d6d6 guibg=#797979 gui=NONE
  highlight VemTabLineLocationSelected guifg=#d6d6d6 guibg=#797979 gui=NONE
  highlight VemTabLineNumberSelected guifg=#d6d6d6 guibg=#797979 gui=NONE
  highlight FloatermBorder guifg=#797979
  highlight FzfBorder guifg=#797979
endfunction

colorscheme afterglow

" }}}

" vim:fdm=marker
