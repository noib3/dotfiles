let s:unfocused_tabs_bg = "#3c3836"
let s:unfocused_tabs_fg = "#a89984"
let s:focused_tabs_bg = "#a89984"
let s:focused_tabs_fg = "#282828"

let s:p = {"normal": {}, "tabline": {}}

let s:p.normal.left = [["#000000", "#000000", 0, 0]]
let s:p.normal.tabsel = [["#000000", "#000000", 0, 0]]
let s:p.normal.middle = [["#000000", "#000000", 0, 0]]
let s:p.normal.right = [["#000000", "#000000", 0, 0]]

let s:p.tabline.left = [[s:unfocused_tabs_fg, s:unfocused_tabs_bg, 0, 0]]
let s:p.tabline.tabsel = [[s:focused_tabs_fg, s:focused_tabs_bg, 0, 0]]
let s:p.tabline.middle = copy(s:p.tabline.left)
let s:p.tabline.right = copy(s:p.tabline.left)

let g:lightline#colorscheme#gruvbox#palette = s:p
