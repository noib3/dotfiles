" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions-=r

" Display vertical columns at 80 characters
setlocal cc=80

" Autopair asterisks
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', "'": "'", '*': '*'}

" Compile the document, open the PDF file and forward search from nvim to Skim
nmap <buffer> <silent> <C-t> :!pandoc % -o %:r.pdf<CR>
nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>
