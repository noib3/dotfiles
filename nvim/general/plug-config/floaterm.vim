let g:floaterm_title = ""
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_autoclose = 2

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
