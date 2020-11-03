" Formatting
setlocal formatoptions-=r
setlocal formatoptions-=o

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Count asterisk as word separator
setlocal iskeyword-=#

" Display vertical columns at 80 and 100 characters
setlocal cc=80,100

" Autopair less-than with greater-than signs
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', "'": "'", '<': '>'}

" Text displayed on folded lines
setlocal foldtext=folding#MarkerFoldsText()
