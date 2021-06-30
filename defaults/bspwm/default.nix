{ colors }:

{
  settings = {
    "window_gap" = 25;
    "border_width" = 2;
    "focus_follows_pointer" = true;
    "normal_border_color" = colors.border.normal;
    "active_border_color" = colors.border.active;
    "focused_border_color" = colors.border.focused;
  };

  monitors = {
    "focused" = [ "1" "2" "3" "4" "5" "videos" ];
  };

  rules = {
    "mpv" = {
      state = "fullscreen";
      desktop = "videos";
      follow = true;
    };

    "Zathura" = {
      state = "tiled";
    };

    "fuzzy-opener" = {
      state = "fullscreen";
    };

    "fuzzy-opened" = {
      state = "fullscreen";
    };
  };

  startupPrograms = [
    "fusuma"
    "unclutter -idle 10"
    "xbanish"
  ];

  extraConfig = ''
    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    systemctl --user start pulseaudio.service
    systemctl --user start mpris-proxy.service
    systemctl --user restart polybar.service
  '';
}
