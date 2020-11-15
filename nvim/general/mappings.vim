let mapleader = ","
let maplocalleader = ","

map <C-a> ^
map <C-e> $
map <silent> <C-s> :w<CR>

imap <C-a> <C-o>I
imap <C-e> <C-o>A
imap <silent> <C-s> <C-o>:w<CR>

nmap ss :%s//g<Left><Left>
nmap <Space> za

cmap <C-a> <C-b>

nnoremap <S-Left> <C-w>h
nnoremap <S-Down> <C-w>j
nnoremap <S-Up> <C-w>k
nnoremap <S-Right> <C-w>l

" floaterm
if &runtimepath =~# 'vim-floaterm'
  nmap <silent> ll :FloatermNew lf<CR>
  nmap <silent> <Leader>i :FloatermNew ipython<CR>
  nmap <silent> <Leader>g :FloatermNew lazygit<CR>
endif

" fzf
if &runtimepath =~# 'fzf'
  map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
  imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>
endif

" vem-tabline
if &runtimepath =~# 'vem-tabline'
  nmap <expr> <silent> <C-w> len(getbufinfo({"buflisted":1})) == 1 ?
                             \ ":q<CR>" :
                             \ "<Plug>vem_delete_buffer-"
  imap <expr> <silent> <C-w> len(getbufinfo({"buflisted":1})) == 1 ?
                             \ "<C-o>:q<CR>" :
                             \ "<C-o><Plug>vem_delete_buffer-"

  for i in range(1, 9)
    execute "nmap <silent> <F" . i . "> :silent! VemTablineGo " . i . "<CR>"
  endfor
endif
