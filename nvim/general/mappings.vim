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
nmap <silent> <Leader>c :execute "setlocal cc=" . (&cc == "" ? "80" : "")<CR>

cmap <C-a> <C-b>

nnoremap <Leader>w <C-w>k
nnoremap <Leader>a <C-w>h
nnoremap <Leader>s <C-w>j
nnoremap <Leader>d <C-w>l
