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

" fzf {{{
map <silent> <C-x><C-e> :FZF --prompt=Edit>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=Edit>\  ~<CR>
imap <expr> <C-s>
  \ fzf#vim#complete(fzf#wrap({
  \   "prefix": '',
  \   "reducer": { lines -> join(lines) },
  \   "options": '--multi "--prompt=Paste> "',
  \ }))
" }}}

" lightline-bufferline {{{
for i in range(1, 9)
  execute "nmap <silent> <F" . i . "> "
        \ . ":call lightline#bufferline#go(" . i . ")<CR>"
endfor
nmap <expr> <silent> <C-w> <SID>close_window_or_delete_buffer()
imap <expr> <silent> <C-w> "\<C-o>" . <SID>close_window_or_delete_buffer()

function! s:close_window_or_delete_buffer()
  if len(getbufinfo({"buflisted":1})) == 1
    return ":q\<CR>"
  else
    return ":BD\<CR>"
  endif
endfunction
" }}}

" vim-floaterm {{{
nmap <silent> ll :call <SID>open_lf_select_current_file()<CR>

" https://github.com/voldikss/vim-floaterm/issues/209#issuecomment-734656183

function! s:select(filename, ...) abort
  silent execute printf('!lf -remote "send select %s"', a:filename)
endfunction

function! s:open_lf_select_current_file()
  let filename = expand('%')
  execute "FloatermNew lf"
  call timer_start(100, function('s:select', [filename]), {'repeat': 3})
endfunction
" }}}

" vim-which-key {{{
nnoremap <silent> <Leader>      :<c-u>WhichKey ","<CR>
nnoremap <silent> <LocalLeader> :<c-u>WhichKey  ","<CR>
" }}}

" vim:fdm=marker
