" ----------------------- NEOVIM CONFIG FILE ------------------------

" Plugs
call plug#begin('~/.config/nvim/plugged')
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'farmergreg/vim-lastplace'
  Plug 'junegunn/goyo.vim'
  Plug 'jiangmiao/auto-pairs'
  " colorschemes
  Plug 'morhetz/gruvbox'
  Plug 'icymind/NeoSolarized'
  Plug 'drewtempelmeyer/palenight.vim'
call plug#end()

" Sets
set fileencoding=utf-8
set clipboard+=unnamedplus
set termguicolors
set tabstop=4
set shiftwidth=4
set expandtab
set number
set relativenumber
set noshowmode
set splitright
set splitbelow
set undofile
set undodir=$HOME/.cache/nvim
set undolevels=1000
set undoreload=10000

" Lets
let g:netrw_home=$HOME.'/.cache/nvim'
let mapleader=","
let maplocalleader=","
let g:is_posix=1

" Maps
nnoremap <C-s> :w<cr>
inoremap <C-s> <esc>:w<cr>a
nnoremap <silent> <C-w> :q<cr>
inoremap <silent> <C-w> <esc>:q<cr>
nnoremap <C-a> ^
vnoremap <C-a> ^
inoremap <C-a> <esc>^i
nnoremap <C-e> g_
vnoremap <C-e> g_
inoremap <C-e> <esc>g_a
nnoremap <leader>w <C-w><C-k>
nnoremap <leader>a <C-w><C-h>
nnoremap <leader>s <C-w><C-j>
nnoremap <leader>d <C-w><C-l>
nnoremap <silent> <leader>g :Goyo<cr>
nnoremap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<cr>
nnoremap <silent> <leader>r :execute "source ~/.config/nvim/init.vim" <bar>
                                   \ echomsg '".config/nvim/init.vim" reloaded'<cr>
nnoremap ss :%s//g<left><left>

" Colorscheme
" colorscheme gruvbox
" colorscheme NeoSolarized
set background=dark
colorscheme palenight

" Highlights
highlight Normal guibg=NONE ctermbg=NONE
highlight Visual guibg=#7aa6da guifg=#ffffff ctermbg=blue ctermfg=white
highlight Comment gui=italic cterm=italic

" Statusline
set statusline=
set statusline+=\ %F\ \  " full path to file in buffer
set statusline+=%m       " modified flag
set statusline+=%h       " help buffer flag
set statusline+=%r       " readonly flag
set statusline+=%=       " switch from left to right side
set statusline+=%y\ \|\  " filetype of file in buffer
set statusline+=%c:80\   " current column:total columns
set statusline+=%LL      " lines in buffer

" Autocmds
autocmd FileType * setlocal formatoptions-=cro
autocmd FileType tex,context,vim,css,yaml setlocal shiftwidth=2
autocmd FileType tex,context inoremap <buffer> <silent> <C-t> <esc>:call TeXCompile()<cr>a
autocmd FileType tex,context nnoremap <buffer> <silent> <C-t> :call TeXCompile()<cr>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<cr>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<cr>
autocmd InsertEnter * norm zz
autocmd BufWritePre * :call StripTrailingWhitespaces()
autocmd BufReadPost *.tex :call PdfOpen()
autocmd BufUnload   *.tex :call PdfClose()

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let l = line(".")
  let c = col(".")
  %s/\s\+$//e
  call cursor(l, c)
endfunction

" Compile a LaTeX/ConTeXt document
function! TeXCompile()
  let filename = expand('%:p')
  execute '!cd $(dirname' shellescape(filename, 1).') && pdflatex -synctex=1' shellescape(filename, 1)
endfunction

" Open the PDF file created by a TeX document
function! PdfOpen()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    execute 'silent !open' shellescape(filename, 1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filename.'"'
    echohl None
  endif
endfunction

" Close the PDF file created by a TeX document
function! PdfClose()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    " let Skim_windows_count = system("yabai -m query --windows | jq -r \".[] | select(.app==\\\"Skim\\\").title\" | wc -l")
    " let Skim_windows = system("yabai -m query --windows | jq -r \".[] | select(.app==\\\"Skim\\\")\"")
    let Skim_windows = system("cat /Users/noibe/windows | jq -r \".[] | select(.app==\\\"Skim\\\")\"")
    let Skim_windows_count = systemlist(Skim_windows." \| jq -r \".id\" | wc -l")
    " if there is just one Skim window and its title matches the filename of
    " the TeX file in the buffer, quit Skim
    if Skim_windows_count == 1
      execute "silent !osascript -e \'quit app \"Skim\"\'"
    " if there are more Skim windows look for the one whose title matches the
    " filename of the TeX file in the buffer and close it
    elseif Skim_windows_count > 1

    endif
  endif
endfunction

" Use SyncTex to jump from a line in a TeX document to its PDF output
function! SyncTeXForwardSearch()
  let filename = expand('%:p:r').'.pdf'
  if filereadable(filename)
    execute 'silent !/Applications/Skim.app/Contents/SharedSupport/displayline' line('.') shellescape(filename, 1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filename.'"'
    echohl None
  endif
endfunction
