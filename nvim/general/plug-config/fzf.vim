let g:fzf_layout = {
\   "window": { "width": 1, "height": 9, "yoffset": 0,
\               "highlight": "FzfBorder", "border": "bottom" }
\ }

map <silent> <C-x><C-e> :FZF --prompt=>\  ~<CR>
imap <silent> <C-x><C-e> <C-o>:FZF --prompt=>\  ~<CR>
