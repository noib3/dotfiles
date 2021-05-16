{ colors }:

{
  settings = {
    "window_gap" = 22;
    "border_width" = 2;
    "focus_follows_pointer" = true;
    "normal_border_color" = colors.border.normal;
    "active_border_color" = colors.border.active;
    "focused_border_color" = colors.border.focused;
  };

  monitors = {
    "focused" = [ "1" "2" "3" "4" "5" ];
  };

  rules = {
    "Zathura" = {
      state = "tiled";
    };

    "\\*:\"fuzzy-opener\"" = {
      state = "fullscreen";
    };

    "\\*:\"fuzzy-opened\"" = {
      state = "fullscreen";
    };
  };

  startupPrograms = [
    "fusuma"
    "listen-node-add"
    "listen-node-remove"
    "unclutter -idle 10"
    "xbanish"
  ];

  extraConfig = ''
    feh --bg-fill --no-fehbg ~/.config/wallpaper.png

    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    systemctl --user start pulseaudio.service
    systemctl --user start mpris-proxy.service
    systemctl --user restart polybar.service
  '';
}
