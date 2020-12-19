fish_vi_key_bindings

# Pro tip: use fish_key_reader to get the character sequence of a key you want
# to bind.

bind --user \cA beginning-of-line
bind --user \cE end-of-line
bind --user yy fish_clipboard_copy
bind --user Y fish_clipboard_copy
bind --user p fish_clipboard_paste

bind --user -M insert \cA beginning-of-line
bind --user -M insert \cE end-of-line
bind --user -M visual \cA beginning-of-line
bind --user -M visual \cE end-of-line

bind --user -M insert \e\x7F backward-kill-word
bind --user -M insert \cW close_window
bind --user -M insert \cX\cD fuzzy_cd
bind --user -M insert \cX\cE fuzzy_edit
bind --user -M insert \cX\cF fuzzy_history
bind --user -M insert \cS fuzzy_search
bind --user -M insert \cG clear_no_scrollback
