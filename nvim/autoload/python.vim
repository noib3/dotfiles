function! python#Run() " {{{1
  if !exists("b:python_run_command")
    let b:python_run_command = "python3 %"
  endif

  let l:errorfile="/tmp/nvim_python.err"
  execute
    \ "!" . b:python_run_command . " 2>&1 | tee " . l:errorfile . ";" .
    \ "exit ${PIPESTATUS[0]}"

  if v:shell_error
    execute "silent cfile " . l:errorfile
  endif
  execute "silent !sudo rm " . l:errorfile
endfunction " }}}1
