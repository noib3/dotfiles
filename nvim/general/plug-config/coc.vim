let g:coc_data_home = "~/.config/nvim/coc"

let g:coc_global_extensions = [
\   "coc-css",
\   "coc-go",
\   "coc-html",
\   "coc-json",
\   "coc-python",
\   "coc-rls",
\   "coc-vimlsp",
\   "coc-vimtex",
\ ]

autocmd CursorHold * silent call CocActionAsync('highlight')

nnoremap <silent> K :call <SID>show_documentation()<CR>
nmap <leader>rn <Plug>(coc-rename)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction
