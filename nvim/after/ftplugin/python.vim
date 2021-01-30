if !exists("current_compiler")
  compiler python3
endif

setlocal formatoptions-=r

let b:surround_{char2nr("f")} = "\1function: \1(\r)"

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>
