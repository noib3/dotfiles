" TODO
" 1. silence compile command for latex and content
" 2. fix yabai focus switching problem
" 3. c + cmd-right is the same as c + $
" 4. understand why sometimes when it's launched with fzf_opener it looks fucked up
" 5. fzf launcher support for multiple files
" 6. fzf launcher sometimes it doesn't launch
" 7. fix all skhd yabai bindings, for ex alt+w with a program on space 3 but spawned from space 2 puts it on space 1
" 8. three terminal on space 1, cmd + alt + n on a terminal, go back to space 1, change focus, go back to space 2
" 9. refactor alacritty configs
" 10. refactor skhd and yabai configs
" 11. cmd - right should go the end of actual line instead of logical line
" 12. vim handle copying and pasting of unicode chars like lambda or plus/minus symbols
" 13. fd ignore .cache and Library with cmd-e and cmd-d
" 14. cmd-e and cmd-d fix colors
" 15. ranger function to open file, eject disk, make wallpaper
" 16. ranger edit a file and move around with cmd-e and cmd-d
" 17. firefox hide tab bar if single tab open, show on hover
" 18. firefox make .app to open torrents
" 19. firefox make bookmarks setup
" 20. firefox make bitwarden setup
" 21. firefox make downloads setup
" 22. firefox rice tridactyl gui
" 23. make program to track time, a binding brings up a menu with the current tasks open, if you click on one it continues that task and tracks the time, binding to stop the task, data saved in json/yaml file, web frontend
" 24. finances web frontend
" 25. remake ndiet
" 26. setup bar with uebersicht
" 27. refactor 2d2small and journal classes
" 28. make closing brackets for $$ in tex
" 29. refactor committed script, calcurse.pid doesn't get pushed, I only try to commit if there is something to commit, option to clear the screen for every git folder
" 30. refactor peek script, see why it throws an error, remove creation of tmp file, program gets pulled from keep once the workout is over
" 31. fix ranger text and pdf previews, pdf previews overflows bug
" 32. ranger show size of file or directory, show elements inside directories
" 33. ranger customize colorscheme

" Plugs
call plug#begin('~/.config/nvim/plugged')
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-endwise'
  Plug 'junegunn/goyo.vim'
  Plug 'farmergreg/vim-lastplace'
  Plug 'Yggdroot/indentLine'
  Plug 'lervag/vimtex'
  " colorschemes
  Plug 'jiangmiao/auto-pairs'
  Plug 'morhetz/gruvbox'
  Plug 'joshdick/onedark.vim'
  "
  Plug 'tridactyl/vim-tridactyl'
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

" Lets
let mapleader=","
let maplocalleader=","
let g:netrw_home=$HOME.'/.cache/nvim'
let g:tex_conceal=''
let g:is_posix=1

" vimtex
let g:vimtex_mappings_enabled=0

" indentLine
let g:indentLine_showFirstIndentLevel=1
let g:indentLine_char='│'
let g:indentLine_first_char='│'
let g:indentLine_defaultGroup='Comment'

" Maps
nnoremap <up> g<up>
vnoremap <up> g<up>
nnoremap <down> g<down>
vnoremap <down> g<down>

imap <C-a> <esc>g^i
nmap <C-a> g^
vmap <C-a> g^
imap <C-e> <esc>g$a
nmap <C-e> g$
vmap <C-e> g_

imap <silent> <C-s> <esc>:w<cr>a
nmap <silent> <C-s> :w<cr>
nmap <silent> <C-w> :q<cr>
imap <silent> <C-w> <esc>:q<cr>

nmap <silent> <leader>c :execute "set cc=" . (&cc == "" ? "80,100" : "")<cr>
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

highlight TabLineSel guibg=#626262 guifg=#ebebeb
highlight TabLine guibg=#393939 guifg=#b6b6b6
highlight TabLineFill guibg=NONE guifg=NONE

highlight VertSplit guibg=#5C6370 guifg=NONE
highlight StatusLine guibg=#5C6370 guifg=NONE
highlight StatusLineNC guibg=#5C6370 guifg=NONE

" Change vertical split character to a space
set fillchars=vert:\  "

" Autocmds
autocmd InsertEnter * norm zz
autocmd BufWritePre * :call StripTrailingWhitespaces()
autocmd FileType * setlocal formatoptions-=cro
autocmd FileType vim,sh,zsh,python,conf execute "set cc=" . (&cc == "" ? "80,100" : "")
autocmd FileType tex,context,vim,css,yaml setlocal shiftwidth=2 tabstop=2
autocmd FileType tex,context nnoremap <buffer> <silent> <C-t> :call TeXCompile()<cr>
autocmd FileType tex,context inoremap <buffer> <silent> <C-t> <esc>:call TeXCompile()<cr>a
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<cr>
autocmd FileType tex,context nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<cr>
autocmd BufReadPost *.tex :call PdfOpen()
autocmd BufUnload   *.tex :call PdfClose()

" Remove trailing whitespace without changing cursor position
function! StripTrailingWhitespaces()
  let [_, line, col, _, _] = getcurpos()
  execute printf('%d substitute/\%%%dc\s\+$//e', line, col+1)
  execute printf('vglobal/\%%%dl/substitute/\s\+$//e', line)
  call cursor(line, col)
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
