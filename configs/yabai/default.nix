{
  config = {
    layout = "bsp";
    focus_follows_mouse = "autofocus";
    window_border = "off";
    window_placement = "second_child";
    top_padding = 20;
    bottom_padding = 30;
    left_padding = 30;
    right_padding = 30;
    window_gap = 20;
  };

  extraConfig = ''
     yabai -m rule --add app="Digital Colour Meter" manage=off
    yabai -m rule --add app="System Preferences" manage=off
    yabai -m rule --add app="Activity Monitor" manage=off
    yabai -m rule --add app="Font Book" manage=off
    yabai -m rule --add app="App Store" manage=off
    yabai -m rule --add app="System Information" manage=off

    yabai -m rule --add title="floating" manage=off

    # Taken from https://github.com/koekeishiya/yabai/issues/719#issuecomment-728140216

    # Focus window after active space changes
    yabai -m signal --add event=space_changed \
      action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"

    # Focus window after active display changes
    yabai -m signal --add event=display_changed \
      action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"
  '';
}
