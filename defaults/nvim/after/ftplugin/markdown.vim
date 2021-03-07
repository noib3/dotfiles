setlocal spell
setlocal spelllang=en_us,it
setlocal textwidth=79

let b:delimitMate_quotes = "\" ' ` *"

nmap <buffer> <silent> <LocalLeader>p <Plug>MarkdownPreview
nmap <buffer> <silent> <LocalLeader>k <Plug>MarkdownPreviewStop
