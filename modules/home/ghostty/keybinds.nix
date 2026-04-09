{ lib, isLinux, ... }:

[
  "alt+escape=reload_config"
  # Create splits.
  "super+g>left=new_split:left"
  "super+g>right=new_split:right"
  "super+g>up=new_split:up"
  "super+g>down=new_split:down"
  # Navigate splits (only if one exists in the given direction).
  "performable:shift+left=goto_split:left"
  "performable:shift+right=goto_split:right"
  "performable:shift+up=goto_split:up"
  "performable:shift+down=goto_split:down"
  # Unbind these default keybindings.
  "super+d=unbind"
  "super+k=unbind"
  "super+t=unbind"
  "super+w=unbind"
  "super+up=unbind"
  "super+down=unbind"
  "super+left=unbind"
  "super+right=unbind"
]
++ lib.lists.optionals isLinux [
  "super+c=copy_to_clipboard"
  "super+v=paste_from_clipboard"
  "super+n=new_window"
  "super+equal=increase_font_size:1"
  "super+minus=decrease_font_size:1"
  "super+zero=reset_font_size"
]
