setlocal spell
setlocal spelllang=en_us,en_gb,it
setlocal textwidth=79

let b:delimitMate_quotes = "\" ' ` *"

nmap <buffer> <silent> <LocalLeader>p <Cmd>MarkdownPreview<CR>
nmap <buffer> <silent> <LocalLeader>k <Cmd>MarkdownPreviewStop<CR>
