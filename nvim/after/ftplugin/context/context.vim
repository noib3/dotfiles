" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions-=t
set formatoptions-=o
set formatoptions-=j

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Autopair dollar signs
let g:AutoPairs['$']='$'

" Mappings to compile the document, open the PDF file and forward search from the tex to the PDF
nmap <buffer> <silent> <C-t> :ConTeXt<CR>
nmap <buffer> <silent> <localleader>p :call tex#PdfOpen()<cr>
nmap <buffer> <silent> <localleader>f :call tex#SkimForwardSearch()<cr>
