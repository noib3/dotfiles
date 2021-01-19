let mapleader = ","
let maplocalleader = ","

map <C-a> ^
map <C-e> $

imap <C-a> <C-o>I
imap <C-e> <C-o>A
inoremap <M-BS> <C-w>

nmap <silent> <C-s> :w<CR>
nmap ss :%s//g<Left><Left>
nmap <Space> za

cmap <C-a> <C-b>

nnoremap <S-Left> <C-w>h
nnoremap <S-Down> <C-w>j
nnoremap <S-Up> <C-w>k
nnoremap <S-Right> <C-w>l
