let g:lightline = {}
let g:lightline.colorscheme = g:colorscheme
let g:lightline.tabline = { "left": [["buffers"]], "right": [] }
let g:lightline.tabline_subseparator = { "left": "", "right": "" }
let g:lightline.component_expand = { "buffers": "lightline#bufferline#buffers" }
let g:lightline.component_type = { "buffers": "tabsel" }
let g:lightline.component_raw = { "buffers": 1 }
