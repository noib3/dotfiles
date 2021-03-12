{ colors }:

{
  config = {
    window_placement = "second_child";
    window_shadow = "on";
    window_border = "on";
    window_border_width = 4;
    normal_window_border_color = colors.normal_window_border;
    active_window_border_color = colors.active_window_border;
    layout = "bsp";
    external_bar = "all:20:0";
    top_padding = 20;
    bottom_padding = 20;
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
    yabai -m rule --add app="Logi Options" manage=off

    yabai -m rule --add title="floating" manage=off

    # https://github.com/koekeishiya/yabai/issues/719#issuecomment-728140216

    # focus window after active space changes
    yabai -m signal --add event=space_changed \
      action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"

    # focus window after active display changes
    yabai -m signal --add event=display_changed \
      action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"
  '';
}
