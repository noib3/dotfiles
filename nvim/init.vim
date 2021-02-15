" Load plugins {{{1
call plug#begin('~/.config/nvim/plugged')
Plug 'dense-analysis/ale'
Plug 'bfontaine/Brewfile.vim'
Plug 'rhysd/clever-f.vim'
Plug 'nvim-lua/completion-nvim'
Plug 'Raimondi/delimitMate'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'morhetz/gruvbox'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'neovim/nvim-lspconfig'
" Plug 'nvim-treesitter/nvim-treesitter'
Plug 'joshdick/onedark.vim'
Plug 'rust-lang/rust.vim'
Plug 'tweekmonster/startuptime.vim'
Plug 'godlygeek/tabular'
" Plug 'SirVer/ultisnips'
Plug 'danilo-augusto/vim-afterglow'
Plug 'qpkorr/vim-bufkill'
Plug 'tpope/vim-commentary'
Plug 'ryanoasis/vim-devicons'
Plug 'dag/vim-fish'
Plug 'voldikss/vim-floaterm'
Plug 'fatih/vim-go'
Plug 'elzr/vim-json'
Plug 'farmergreg/vim-lastplace'
Plug 'shime/vim-livedown'
Plug 'embear/vim-localvimrc'
Plug 'plasticboy/vim-markdown'
Plug 'LnL7/vim-nix'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-scriptease'
Plug 'timakro/vim-searchant'
Plug 'tpope/vim-surround'
Plug 'thinca/vim-textobj-between'
Plug 'somini/vim-textobj-fold'
Plug 'kana/vim-textobj-user'
Plug 'cespare/vim-toml'
Plug 'tridactyl/vim-tridactyl'
Plug 'liuchengxu/vim-which-key'
Plug 'lervag/vimtex'
call plug#end()
" }}}1

" Settings {{{1
set autochdir
set clipboard+=unnamedplus
set colorcolumn=80
set completeopt=menuone,noinsert
set expandtab
set fillchars=fold:\ ,vert:\ ,
set hidden
set ignorecase
set iskeyword-=_
set laststatus=0
set linebreak
set list
set listchars=tab:\⇥\ ,space:·,eol:¬
set mouse=a
set noswapfile
set number
set relativenumber
set scrolloff=1
set shiftwidth=2
set showbreak=↪\ "
set smartcase
set spellfile=$PRIVATEDIR/nvim/spell/en.utf-8.add
set splitright
set splitbelow
set tabstop=2
set termguicolors
set textwidth=79
set undofile
" }}}1

" Mappings {{{1
let mapleader = ","
let maplocalleader = ","

map <C-a> ^
map <C-e> $
imap <C-a> <C-o>I
imap <C-e> <C-o>A

nmap <Space> za
nmap <silent> <C-s> :w<CR>
nmap ss :%s//g<Left><Left>
inoremap <M-BS> <C-w>
tnoremap <M-Esc> <C-\><C-n>
cmap <C-a> <C-b>

nnoremap <S-Left> <C-w>h
nnoremap <S-Down> <C-w>j
nnoremap <S-Up> <C-w>k
nnoremap <S-Right> <C-w>l
" }}}1

" Configure plugins {{{1

" ale {{{2
let g:ale_disable_lsp = 1
let g:ale_fix_on_save = 1
let g:ale_linters = {
      \ 'python': ['flake8', 'pyls']
      \ }
let g:ale_fixers = {
      \ '*': ['remove_trailing_lines', 'trim_whitespace'],
      \ 'python': ['autopep8', 'isort'],
      \ }
" }}}2
" completion-nvim {{{2
let g:completion_enable_auto_paren = 1
" }}}2
" delimitMate {{{2
let delimitMate_expand_cr = 1
" }}}2
" fzf.vim {{{2
let g:fzf_layout = {
      \   'window': { 'width': 1, 'height': 9, 'yoffset': 0,
      \               'highlight': 'FzfBorder', 'border': 'bottom' }
      \ }

map <silent> <C-x><C-e> :FZF --prompt=Edit>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=Edit>\  ~<CR>
imap <expr> <C-s>
      \ fzf#vim#complete(fzf#wrap({
      \   'prefix': '',
      \   'reducer': { lines -> join(lines) },
      \   'options': '--multi "--prompt=Paste> "',
      \ }))
" }}}2
" goyo.vim {{{2
let g:goyo_linenr = 1

function! s:goyo_enter()
  highlight! NonText guifg=#3b4048 guibg=NONE gui=NONE
endfunction
autocmd! User GoyoEnter nested call <SID>goyo_enter()
" }}}2
" lightline.vim {{{2
let g:lightline = {}
let g:lightline.colorscheme = $COLORSCHEME
let g:lightline.tabline = { 'left': [ ['buffers'] ], 'right': [] }
let g:lightline.tabline_subseparator = { 'left': '', 'right': '' }
let g:lightline.component_expand = { 'buffers': 'lightline#bufferline#buffers' }
let g:lightline.component_type = { 'buffers': 'tabsel' }
let g:lightline.component_raw = { 'buffers': 1 }
" }}}2
" lightline-bufferline {{{2
let g:lightline#bufferline#show_number = 2
let g:lightline#bufferline#number_separator = ': '
let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#icon_position = 'first'
let g:lightline#bufferline#min_buffer_count = 2
let g:lightline#bufferline#clickable = 1

for i in range(1, 9)
  execute 'nmap <silent> <F' . i . '> '
        \ . ':call lightline#bufferline#go(' . i . ')<CR>'
endfor

nmap <expr> <silent> <C-w>
      \ (len(getbufinfo({'buflisted':1})) == 1 ? ':q' : ':bd') . "\<CR>"
imap <expr> <silent> <C-w> "\<C-o>" .
      \ (len(getbufinfo({'buflisted':1})) == 1 ? ':q' : ':bd') . "\<CR>"
" }}}2
" nvim-colorizer.lua {{{2
lua << EOF
require('colorizer').setup ( {"*"}, {names = false} )
EOF
" }}}2
" nvim-lspconfig {{{2
lua << EOF
local lspconfig = require('lspconfig')
vim.lsp.callbacks["textDocument/publishDiagnostics"] = function() end

local custom_lsp_attach = function(client, bufnr)
require('completion').on_attach()

local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local opts = { noremap=true, silent=true }
buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
buf_set_keymap('n', '<Leader>s', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
buf_set_keymap('n', '<Leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
buf_set_keymap('n', '<Leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)

if client.resolved_capabilities.document_formatting then
  vim.api.nvim_exec([[
  augroup lsp_format
    autocmd!
    autocmd BufWritePre * lua vim.lsp.buf.formatting()
  augroup END
  ]], false)
end

if client.resolved_capabilities.document_highlight then
  vim.api.nvim_exec([[
  augroup lsp_highlight
    autocmd!
    autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
    autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
  augroup END
  ]], false)
end
end

local servers = { 'jedi_language_server', 'vimls' }
for _, server in ipairs(servers) do
  lspconfig[server].setup { on_attach = custom_lsp_attach }
end
EOF
" }}}2
" " nvim-treesitter {{{2
" lua <<EOF
" require'nvim-treesitter.configs'.setup {
"   ensure_installed = "maintained",
"   highlight = {
"     enable = true,
"   },
" }
" EOF
" " }}}2
" rust.vim {{{2
let g:rustfmt_autosave = 1
let g:cargo_makeprg_params = 'run'
" }}}2
" ultisnips {{{2
let g:UltiSnipsExpandTrigger = '<Tab>'
let g:UltiSnipsJumpForwardTrigger = '<Tab>'
let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
let g:UltiSnipsSnippetDirectories = ['UltiSnips']
" }}}2
" vim-floaterm {{{2
let g:floaterm_title = ''
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_autoclose = 2

nmap <silent> ll :call <SID>open_lf_select_current_file()<CR>
nmap <silent> lg :FloatermNew lazygit<CR>
nmap <silent> <Leader>tt :FloatermNew<CR>

" https://github.com/voldikss/vim-floaterm/issues/209#issuecomment-734656183

function! s:select(filename, ...) abort
  silent execute printf('!lf -remote "send select %s"', a:filename)
endfunction

function! s:open_lf_select_current_file()
  let filename = expand('%')
  execute 'FloatermNew lf'
  call timer_start(100, function('s:select', [filename]), {'repeat': 3})
endfunction
" }}}2
" vim-json {{{2
let g:vim_json_syntax_conceal = 0
" }}}2
" vim-localvimrc {{{2
let g:localvimrc_file_directory_only = 1
let g:localvimrc_sandbox = 0
let g:localvimrc_ask = 0
" }}}2
" vim-markdown {{{2
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled = 1
" }}}2
" vim-which-key {{{2
nnoremap <silent> <Leader>      :<c-u>WhichKey ","<CR>
nnoremap <silent> <LocalLeader> :<c-u>WhichKey  ","<CR>
" }}}2
" vimtex {{{2
let g:vimtex_compiler_enabled = 0
let g:vimtex_format_enabled = 1
let g:vimtex_syntax_conceal_default = 0
let g:vimtex_toc_show_preamble = 0
let g:vimtex_toc_config = {
      \   'indent_levels': 1,
      \   'layers' : ['content', 'include'],
      \   'show_help': 0,
      \   'split_width' : 40,
      \   'tocdepth': 6,
      \ }
let g:vimtex_view_method = "skim"
let g:vimtex_view_skim_reading_bar = 0
" }}}2

" }}}1

" Commands {{{1
command! Ipysp FloatermNew --height=0.5 --wintype=normal --name=repl
         \  --position=bottom ipython --no-confirm-exit
command! Ipyvsp FloatermNew --width=0.5 --wintype=normal --name=repl
         \  --position=right ipython --no-confirm-exit
" }}}1

" Colorschemes {{{1
let g:colorscheme = $COLORSCHEME

augroup colorschemes
  autocmd!
  autocmd ColorScheme * highlight Normal guibg=NONE
  autocmd ColorScheme * highlight Comment gui=italic
  autocmd ColorScheme * highlight texComment gui=italic
  autocmd ColorScheme * highlight goType gui=italic
  autocmd ColorScheme afterglow call s:patch_afterglow_colors()
  autocmd ColorScheme gruvbox call s:patch_gruvbox_colors()
  autocmd ColorScheme onedark call s:patch_onedark_colors()
augroup END

function! s:patch_afterglow_colors() " {{{2
  let g:terminal_color_0 = '#1a1a1a'
  let g:terminal_color_1 = '#ac4142'
  let g:terminal_color_2 = '#b4c973'
  let g:terminal_color_3 = '#e5b567'
  let g:terminal_color_4 = '#6c99bb'
  let g:terminal_color_5 = '#b05279'
  let g:terminal_color_6 = '#9e86c8'
  let g:terminal_color_7 = '#d6d6d6'
  highlight Visual guifg=#d6d6d6 guibg=#5a647e
  highlight VertSplit guifg=NONE guibg=#393939
  highlight SpellBad guifg=#ac4142 gui=underline
  highlight SpellCap guifg=#e87d3e gui=NONE
  highlight htmlItalic guifg=#9e86c8 gui=italic
  highlight htmlBold guifg=#e87d3e gui=bold
  highlight FzfBorder guifg=#797979
endfunction " }}}2
function! s:patch_gruvbox_colors() " {{{2
  let g:terminal_color_0 = '#282828'
  let g:terminal_color_1 = '#cc241d'
  let g:terminal_color_2 = '#98971a'
  let g:terminal_color_3 = '#d79921'
  let g:terminal_color_4 = '#458588'
  let g:terminal_color_5 = '#b16286'
  let g:terminal_color_6 = '#689d6a'
  let g:terminal_color_7 = '#ebdbb2'
  highlight StatusLine guifg=NONE guibg=#83a598
  highlight VertSplit guifg=NONE guibg=#3c3836
  highlight SpellBad guifg=#cc241d gui=underline
  highlight SpellCap guifg=#fe8019 gui=NONE
  highlight htmlItalic guifg=#b16286 gui=italic
  highlight htmlBold guifg=#fe8019 gui=bold
  highlight FzfBorder guifg=#a89984
  highlight texComment guifg=#928374
endfunction " }}}2
function! s:patch_onedark_colors() " {{{2
  let g:terminal_color_0 = '#282c34'
  let g:terminal_color_1 = '#e06c75'
  let g:terminal_color_2 = '#98c379'
  let g:terminal_color_3 = '#e5c07b'
  let g:terminal_color_4 = '#61afef'
  let g:terminal_color_5 = '#c678dd'
  let g:terminal_color_6 = '#56b6c2'
  let g:terminal_color_7 = '#abb2bf'
  hi SpellBad guifg=#e06c75 gui=underline
  hi SpellCap guifg=#d19a66 gui=NONE
  hi VertSplit guifg=NONE guibg=#3e4452
  hi LspReferenceRead guibg=#3e4452
  hi LspReferenceText guibg=#3e4452
  hi LspReferenceWrite guibg=#3e4452
  hi Whitespace guifg=#5c6370
  hi FzfBorder guifg=#5c6073
endfunction " }}}2

if g:colorscheme ==# 'gruvbox'
  let g:gruvbox_invert_selection=0
endif

execute 'colorscheme ' . g:colorscheme
" }}}1

" Miscellaneous {{{1
augroup all
  autocmd!
  autocmd BufLeave * call s:AutoSaveWinView()
  autocmd BufEnter * call s:AutoRestoreWinView()
  autocmd BufRead *.cls setlocal filetype=tex
  autocmd BufRead lfrc,skhdrc,.gitignore,ignore setlocal filetype=conf
augroup END

" https://vim.fandom.com/wiki/Avoid_scrolling_when_switch_buffers {{{2
" Save current view settings on a per-window, per-buffer basis.
function! s:AutoSaveWinView()
  if !exists('w:SavedBufView')
    let w:SavedBufView = {}
  endif
  let w:SavedBufView[bufnr("%")] = winsaveview()
endfunction

" Restore current view settings.
function! s:AutoRestoreWinView()
  let buf = bufnr('%')
  if exists('w:SavedBufView') && has_key(w:SavedBufView, buf)
    let v = winsaveview()
    let atStartOfFile = v.lnum == 1 && v.col == 0
    if atStartOfFile && !&diff
      call winrestview(w:SavedBufView[buf])
    endif
    unlet w:SavedBufView[buf]
  endif
endfunction
" }}}2
" }}}1

" vim:fdm=marker
