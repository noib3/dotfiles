setlocal spell
setlocal spelllang=en_us,it
setlocal textwidth=79

nmap <buffer> <silent> <C-t>
  \ <Cmd>!echo "rmarkdown::render('%')" <Bar> R --vanilla<CR>
