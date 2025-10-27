{ lib, isLinux, ... }:

[
  "super+d=text:\\x18\\x04" # C-x C-d
  "super+e=text:\\x18\\x05" # C-x C-e
  "super+h=text:\\x18\\x06" # C-x C-f
  "super+k=text:\\x18\\x07" # C-x C-g
  "super+l=text:\\x07" # C-g
  "super+r=text:\\x18\\x12" # C-x C-r
  "super+s=text:\\x13" # C-s
  "super+t=text:\\x18\\x14" # C-x C-t
  "super+w=text:\\x17" # C-w
  "super+x=text:\\x18\\x18" # C-x C-x
  "super+up=text:\\x15" # C-u
  "super+down=text:\\x04" # C-d
  "super+left=text:\\x01" # C-a
  "super+right=text:\\x05" # C-e
  "super+backspace=text:\\x15" # C-u
  "super+one=text:\\x1b\\x4f\\x50" # F1
  "super+two=text:\\x1b\\x4f\\x51" # F2
  "super+three=text:\\x1b\\x4f\\x52" # F3
  "super+four=text:\\x1b\\x4f\\x53" # F4
  "super+five=text:\\x1b\\x5b\\x31\\x35\\x7e" # F5
  "super+six=text:\\x1b\\x5b\\x31\\x37\\x7e" # F6
  "super+seven=text:\\x1b\\x5b\\x31\\x38\\x7e" # F7
  "super+eight=text:\\x1b\\x5b\\x31\\x39\\x7e" # F8
  "super+nine=text:\\x1b\\x5b\\x32\\x30\\x7e" # F9
  "super+escape=reload_config"

  # Create splits.
  "g>left=new_split:left"
  "g>right=new_split:right"
  "g>up=new_split:up"
  "g>down=new_split:down"

  # Navigate splits (only if one exists in the given direction).
  "performable:shift+left=goto_split:left"
  "performable:shift+right=goto_split:right"
  "performable:shift+up=goto_split:up"
  "performable:shift+down=goto_split:down"
]
++ lib.lists.optionals isLinux [
  "super+c=copy_to_clipboard"
  "super+v=paste_from_clipboard"
  "super+n=new_window"
  "super+equal=increase_font_size:1"
  "super+minus=decrease_font_size:1"
  "super+zero=reset_font_size"
]
