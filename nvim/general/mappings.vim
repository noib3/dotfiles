let mapleader = ","
let maplocalleader = ","

map <C-a> ^
map <C-e> $

imap <C-a> <C-o>I
imap <C-e> <C-o>A

nmap <silent> <C-s> :w<CR>
nmap ss :%s//g<Left><Left>
nmap <Space> za

cmap <C-a> <C-b>

nnoremap <S-Left> <C-w>h
nnoremap <S-Down> <C-w>j
nnoremap <S-Up> <C-w>k
nnoremap <S-Right> <C-w>l

" fzf
if &runtimepath =~# 'fzf'
  map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
  imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>
  imap <expr> <C-s> fzf#vim#complete#path($FZF_DEFAULT_COMMAND)
endif

" lightline-bufferline
if &runtimepath =~# 'lightline-bufferline'
  for i in range(1, 9)
    execute "nmap <silent> <F" . i . "> "
            \ . ":call lightline#bufferline#go(" . i . ")<CR>"
  endfor
  nmap <expr> <silent> <C-w> <SID>close_window_or_delete_buffer()
  imap <expr> <silent> <C-w> "\<C-o>" . <SID>close_window_or_delete_buffer()
endif

function! s:close_window_or_delete_buffer()
  if len(getbufinfo({"buflisted":1})) == 1 || winnr("$") != 1
    return ":q\<CR>"
  else
    return ":bdelete\<CR>"
  endif
endfunction

" vim-floaterm
if &runtimepath =~# 'vim-floaterm'
  nmap <expr> <silent> ll ":FloatermNew lf\<CR>:select " . expand("%") . "\<CR>"
  " nmap <expr> <silent> ll <SID>open_lf_select_current_file()
  nmap <silent> <Leader>i :FloatermNew ipython<CR>
  nmap <silent> <Leader>g :FloatermNew lazygit<CR>
endif

function! s:open_lf_select_current_file()
  execute "FloatermNew lf"
  execute "silent !lf -remote \"send select " . expand("%") . "\""
endfunction
