"  _  _  ____  _____  _  _  ____  __  __
" ( \( )( ___)(  _  )( \/ )(_  _)(  \/  )
"  )  (  )__)  )(_)(  \  /  _)(_  )    (
" (_)\_)(____)(_____)  \/  (____)(_/\/\_)

" TODO
" 2. vim indent change color to the same color of comments
" 3. when saving all trailing whitespace is deleted, but don't move the cursor from the column you're on
" 4. silence compile command for latex and content
" 5. reproduce yabai focus switching problem
" 6. c + cmd-right is the same as c + $
" 7. understand why sometimes when it's launched with fzf_opener it looks fucked up
" 8. fzf launcher support for multiple files
" 9. fzf launcher sometimes it doesn't launch
" 10. fix all skhd yabai bindings, for ex alt+w with a program on space 3 but spawned from space 2 puts it on space 1
" 11. brave on space 1, nvim + spagnolo + pdf on space 2, cmd + alt + n on pdf file, alt + 1, alt + 2, alt + 3 and pdf isn't focused
" 12. comment and refactor redshift notify-change
" 13. refactor alacritty configs
" 14. refactor skhd and yabai configs
" 15. cmd - right should go the end of actual line instead of logical line
" 16. vim handle copying and pasting of unicode chars like lambda or plus/minus symbols
" 17. fd ignore .cache and Library with cmd-e and cmd-d
" 18. cmd-e and cmd-d fix colors
" 19. ranger function to open file, eject disk, make wallpaper
" 20. ranger edit a file and move around with cmd-e and cmd-d
" 21. firefox hide tab bar if single tab open, show on hover
" 22. firefox make .app to open torrents
" 22. firefox make bookmarks setup
" 23. firefox make bitwarden setup
" 24. firefox make downloads setup
" 25. firefox rice tridactyl gui
" 26. make program to track time, a binding brings up a menu with the current tasks open, if you click on one it continues that task and tracks the time, binding to stop the task, data saved in json/yaml file, web frontend
" 27. finances web frontend
" 28. remake ndiet
" 29. setup bar with uebersicht
" 30. refactor 2d2small and journal classes
" 31. make closing brackets for $$ in tex

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

" indentLine
let g:indentLine_showFirstIndentLevel=1
let g:indentLine_char='│'
let g:indentLine_first_char='│'
let g:indentLine_color_gui='#5c6370'

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
