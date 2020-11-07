let g:floaterm_title = ""
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_autoclose = 2

nmap <silent> ll :FloatermNew lf<CR>
nmap <silent> <Leader>i :FloatermNew ipython<CR>
nmap <silent> <Leader>g :FloatermNew lazygit<CR>
