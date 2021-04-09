{ colors }:

{
  settings = {
    "window_gap" = 25;
    "border_width" = 2;
    "focus_follows_pointer" = true;
    "normal_border_color" = colors.normal_border;
    "active_border_color" = colors.active_border;
    "focused_border_color" = colors.focused_border;
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
    systemctl --user restart polybar.service
  '';
}
