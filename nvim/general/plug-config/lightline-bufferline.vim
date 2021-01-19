let g:lightline#bufferline#show_number = 2
let g:lightline#bufferline#number_separator = ": "
let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#icon_position = "first"
let g:lightline#bufferline#min_buffer_count = 2
let g:lightline#bufferline#clickable = 1

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
