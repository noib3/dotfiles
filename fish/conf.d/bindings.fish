fish_vi_key_bindings

bind --user \ca beginning-of-line
bind --user \ce end-of-line
bind --user yy fish_clipboard_copy
bind --user Y fish_clipboard_copy
bind --user p fish_clipboard_paste

bind --user -M insert \ca beginning-of-line
bind --user -M insert \ce end-of-line
bind --user -M visual \ca beginning-of-line
bind --user -M visual \ce end-of-line

bind --user -M insert \cw close_window
bind --user -M insert \cx\cd fuzzy_cd
bind --user -M insert \cx\ce fuzzy_edit
bind --user -M insert \cx\cf fuzzy_history
bind --user -M insert \cs fuzzy_search
bind --user -M insert \cg clear_no_scrollback
