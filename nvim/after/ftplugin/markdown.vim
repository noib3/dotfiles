setlocal formatoptions-=r

setlocal colorcolumn=80

nmap <buffer> <silent> <C-t> :!pandoc % -o %:r.pdf<CR>
nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>

let b:AutoPairs = {'(': ')', '[': ']', '{': '}', "'": "'", '*': '*'}
