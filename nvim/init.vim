" ----------------------- NEOVIM CONFIG FILE ------------------------

" TODO
" 1. color splits
" 2. color background and foreground of active and non active tabs
" 4. clear the command line instead of cluttering it when saving
" 5. extend tab width to the max allowed (1 tab -> 100%, 2 tabs -> 50% etc.)
" 6. unsaved changes mark is a single * after the filename without any spaces
" 7. make tabs numbered
" 8. filetype icon before tab number
" 9. command to hide and show the tabline
" 10. vim indent change color to the same color of comments
" 12. set shiftwidth=2 for tex files
" 13. when saving all trailing whitespace is deleted, but don't move the cursor from the column you're on
" 14. get another column at 100 chars
" 15. silence compile command for latex and content

" Plugs
call plug#begin('~/.config/nvim/plugged')
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'junegunn/goyo.vim'
  Plug 'farmergreg/vim-lastplace'
  Plug 'Yggdroot/indentLine'
  " colorschemes
  Plug 'jiangmiao/auto-pairs'
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
call plug#end()

" Sets
set splitright splitbelow
set number relativenumber
set shiftwidth=4
set tabstop=4
set expandtab
set clipboard+=unnamedplus
set termguicolors
set noshowmode
set undofile
set laststatus=0

" Tabline
set showtabline=1
set tabline+=\ %t\ \  " full path to file in buffer
set tabline+=%m       " modified flag
set tabline+=%h       " help buffer flag
set tabline+=%r       " readonly flag
set tabline+=%=       " switch from left to right side
set tabline+=%y\      " filetype of file in buffer

" Lets
let mapleader=","
let maplocalleader=","
let g:netrw_home=$HOME.'/.cache/nvim'
let g:tex_conceal=''
let g:is_posix=1

" indentLine
let g:indentLine_showFirstIndentLevel=1
let g:indentLine_char='│'
let g:indentLine_first_char='│'
let g:indentLine_color_gui='#5C6370'

" Maps
imap <C-a> <esc>^i
nmap <C-a> ^
vmap <C-a> ^
imap <C-e> <esc>$a
nmap <C-e> $
vmap <C-e> g_
imap <silent> <C-s> <esc>:w<cr>a
nmap <silent> <C-s> :w<cr>
nmap <silent> <C-w> :q<cr>
imap <silent> <C-w> <esc>:q<cr>
nmap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80" : "")<cr>
nmap <silent> <leader>r :execute "source ~/.config/nvim/init.vim"<cr>
nmap ss :%s//g<left><left>
nnoremap <leader>w <C-w><C-k>
nnoremap <leader>a <C-w><C-h>
nnoremap <leader>s <C-w><C-j>
nnoremap <leader>d <C-w><C-l>

" Colorscheme
colorscheme onedark

" Highlights
highlight Normal guibg=NONE ctermbg=NONE
highlight Visual guibg=#7aa6da guifg=#ffffff ctermbg=blue ctermfg=white
highlight Comment gui=italic cterm=italic
" highlight TabLineSel guibg=#7aa6da guifg=#abb2bf

" Autocmds
autocmd InsertEnter * norm zz
autocmd BufWritePre * :call StripTrailingWhitespaces()
autocmd FileType * setlocal formatoptions-=cro
autocmd FileType vim,sh,zsh,python,conf execute "set cc=" . (&cc == "" ? "80" : "")
autocmd FileType tex,context,vim,css,yaml setlocal shiftwidth=2 tabstop=2
autocmd FileType tex,context nnoremap <buffer> <silent> <C-t> :call TeXCompile()<cr>
autocmd FileType tex,context inoremap <buffer> <silent> <C-t> <esc>:call TeXCompile()<cr>a
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<cr>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<cr>
autocmd BufReadPost *.tex :call PdfOpen()
autocmd BufUnload   *.tex :call PdfClose()

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let l = line('.')
  let c = col('.')
  %s/\s\+$//e
  call cursor(l, c)
endfunction

" Compile a LaTeX/ConTeXt document
function! TeXCompile()
  let filepath = expand('%:p')
  execute "!cd $(dirname ".shellescape(filepath,1).") && pdflatex -synctex=1 ".shellescape(filepath,1)
endfunction

" Open the PDF file created by a TeX document
function! PdfOpen()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute 'silent !open '.shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction

" Close the PDF file created by a TeX document
function! PdfClose()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    let yabai_windows = json_decode(join(systemlist('yabai -m query --windows')))
    let skim_windows = filter(yabai_windows, 'v:val.app=="Skim"')
    " if there is just one Skim window and its title matches the filename of
    " the file in the buffer, quit Skim
    if len(skim_windows) == 1
      execute "silent !osascript -e \'quit app \"Skim\"\'"
    " if there are more Skim windows look for the one whose title matches the
    " filename of the file in the buffer and close it
    elseif len(skim_windows) > 1
      let filename = system("basename ".shellescape(filepath,1))
      for window in skim_windows
        if system("sed 's/\.pdf.*/.pdf/'", window.title) == filename
          execute "silent !yabai -m window --focus ".shellescape(window.id,1)." && yabai -m window --close && yabai -m window --focus recent"
        endif
      endfor
    endif
  endif
endfunction

" Use SyncTex to jump from a line in a TeX document to its PDF output
function! SyncTeXForwardSearch()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute "silent !/Applications/Skim.app/Contents/SharedSupport/displayline ".line(".")." ".shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction
