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
nmap <buffer> <silent> <localleader>p :call tex#PdfOpen()<cr>
nmap <buffer> <silent> <localleader>f :call tex#SkimForwardSearch()<cr>

" Open the ToC in a floating window and open documentation on CTAN
" nmap <silent> <Leader>t <plug>(vimtex-toc-open)
nmap <silent> <Leader>t :call vimtex#fzf#run('ctli', g:fzf_layout)
nmap <Leader>a :VimtexDocPackage<Space>
