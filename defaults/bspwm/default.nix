{ theme, colors }:

{
  settings = {
    "border_width" = 2;
    "window_gap" = 25;
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
  };

  startupPrograms = [
    "fusuma"
    "polybar bar"
  ];

  extraConfig = ''
    feh --bg-fill /home/noib3/Sync/wallpapers/${theme}.png

    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    systemctl --user start pulseaudio.service
  '';
}
