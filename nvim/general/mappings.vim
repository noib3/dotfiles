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

nnoremap <Leader>w <C-w>k
nnoremap <Leader>a <C-w>h
nnoremap <Leader>s <C-w>j
nnoremap <Leader>d <C-w>l

" coc-snippets
if &runtimepath =~# 'coc.nvim'
  inoremap <expr> <silent> <Tab>
    \ coc#expandableOrJumpable() ?
    \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
    \ <SID>check_back_space() ? "\<Tab>" : coc#refresh()
endif

function! s:check_back_space() abort
  let col = col(".") - 1
  return !col || getline(".")[col - 1] =~# '\s'
endfunction

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
