call textobj#user#plugin("markdown", {
\   "asterisks-a": {
\     "pattern": "[\*][^$]*[\*]",
\     "select": [],
\   },
\   "asterisks-i": {
\     "pattern": "[\*]\zs[^$]*\ze[\*]",
\     "select": [],
\   },
\ })

augroup markdown_textobjs
  autocmd!
  autocmd FileType markdown call textobj#user#map("markdown", {
  \   "asterisks-a": {
  \     "select": "<buffer> a*",
  \   },
  \   "asterisks-i": {
  \     "select": "<buffer> i*",
  \   },
  \ })
augroup END
