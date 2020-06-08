setlocal shiftwidth=2 tabstop=2

execute "set cc=" . (&cc == "" ? "80,100" : "")
