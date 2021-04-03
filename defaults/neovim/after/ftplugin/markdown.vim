setlocal spell
setlocal spelllang=en_us,it
setlocal textwidth=79

let b:delimitMate_quotes = "\" ' ` *"

" nmap <buffer> <LocalLeader>p <Plug>MarkdownPreview
" nmap <buffer> <LocalLeader>k <Plug>MarkdownPreviewStop
nmap <buffer> <silent> <LocalLeader>p <Cmd>MarkdownPreview<CR>
nmap <buffer> <silent> <LocalLeader>k <Cmd>MarkdownPreviewStop<CR>
