{ lib, isLinux, ... }:

[
  "alt+escape=reload_config"
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
