{ colors, scripts }:

{
  settings = {
    "window_gap" = 25;
    "top_padding" = 20;
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
  };

  startupPrograms = [
    "fusuma"
    "unclutter -idle 10"
    "xbanish"
    "${scripts.mpv-focus-prev}/bin/mpv-focus-prev"
  ];

  extraConfig = ''
    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    systemctl --user start pulseaudio.service
    systemctl --user start mpris-proxy.service
    systemctl --user restart polybar.service
  '';
}
