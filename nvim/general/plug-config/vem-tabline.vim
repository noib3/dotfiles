let g:vem_tabline_show_number = "index"
let g:vem_tabline_number_symbol = ": "

for i in range(1, 9)
  execute "nmap <silent> <F" . i . "> :silent! VemTablineGo " . i . "<CR>"
endfor

nmap <expr> <silent> <C-w> len(getbufinfo({"buflisted":1})) == 1 ?
                           \ ":q<CR>" :
                           \ "<Plug>vem_delete_buffer-"
imap <expr> <silent> <C-w> len(getbufinfo({"buflisted":1})) == 1 ?
                           \ "<C-o>:q<CR>" :
                           \ "<C-o><Plug>vem_delete_buffer-"
