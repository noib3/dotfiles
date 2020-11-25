let s:unfocused_tabs_bg = "#393939"
let s:unfocused_tabs_fg = "#a1a1a1"
let s:focused_tabs_bg = "#797979"
let s:focused_tabs_fg = "#d6d6d6"

let s:p = {"normal": {}, "tabline": {}, "inactive": {}}

let s:p.normal.left = [ [ s:unfocused_tabs_bg, s:unfocused_tabs_bg, 0, 0 ] ]
let s:p.normal.tabsel = copy(s:p.normal.left)
let s:p.normal.middle = copy(s:p.normal.left)
let s:p.normal.right = copy(s:p.normal.left)

let s:p.tabline.left = [ [ s:unfocused_tabs_fg, s:unfocused_tabs_bg, 0, 0 ] ]
let s:p.tabline.tabsel = [ [ s:focused_tabs_fg, s:focused_tabs_bg, 0, 0 ] ]
let s:p.tabline.middle = copy(s:p.tabline.left)
let s:p.tabline.right = copy(s:p.tabline.left)

let s:p.inactive.left = copy(s:p.normal.left)
let s:p.inactive.tabsel = copy(s:p.normal.left)
let s:p.inactive.middle = copy(s:p.normal.left)
let s:p.inactive.right = copy(s:p.normal.left)

let g:lightline#colorscheme#afterglow#palette = s:p
