let g:coc_config_home = "~/.config/nvim/coc"
let g:coc_data_home = "~/.config/nvim/coc"

let g:coc_global_extensions = [
\   "coc-css",
\   "coc-json",
\   "coc-python",
\   "coc-snippets",
\   "coc-vimlsp",
\   "coc-vimtex",
\ ]

" coc-snippets

inoremap <silent> <expr> <Tab>
  \ coc#expandableOrJumpable() ?
  \ "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
  \ <SID>check_back_space() ? "\<Tab>" : coc#refresh()

function! s:check_back_space() abort
  let col = col(".") - 1
  return !col || getline(".")[col - 1] =~# '\s'
endfunction

let g:coc_snippet_next = "<Tab>"
let g:coc_snippet_prev = "<S-Tab>"
