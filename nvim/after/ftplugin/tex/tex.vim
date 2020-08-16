" Filename:   nvim/after/ftplugin/tex/tex.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair dollar signs
let b:coc_pairs = [["$", "$"]]

" Compile the document, open the PDF file and forward search from nvim to Skim
nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
nmap <buffer> <silent> <localleader>p :call tex#PdfOpen()<CR>
nmap <buffer> <silent> <localleader>f :call tex#SkimForwardSearch()<CR>

" Open vimtex's ToC window
nmap <silent> <Leader><Leader> <plug>(vimtex-toc-open)

" Autoinsert '\item ' on the next line if the current line has '\item' in it
" Inspired by the following Stack Overflow answer
"   https://stackoverflow.com/a/2554770/10786411:
inoremap <expr> <buffer> <CR> "\r".tex#AutoInsertItem()
nmap <expr> <buffer> o "o".tex#AutoInsertItem()
nmap <expr> <buffer> O "O".tex#AutoInsertItem()
