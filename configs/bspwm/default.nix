{ colors }:

let
  pkgs = import <nixpkgs> { };

  mpv-focus-prev = pkgs.writeShellScriptBin "mpv-focus-prev"
    (builtins.readFile ./scripts/mpv-focus-prev.sh);
in
{
  settings = {
    "window_gap" = 25;
    "top_padding" = 20;
    "border_width" = 2;
    "focus_follows_pointer" = true;
    "normal_border_color" = colors.border.unfocused;
    "active_border_color" = colors.border.unfocused;
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
    "${pkgs.fusuma}/bin/fusuma"
    "${pkgs.unclutter-xfixes}/bin/unclutter -idle 10"
    "${pkgs.xbanish}/bin/xbanish"
    "PATH=$PATH:${pkgs.xdo}/bin:${pkgs.bspwm}/bin ${mpv-focus-prev}/bin/mpv-focus-prev"
  ];

  extraConfig = ''
    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    systemctl --user start pulseaudio.service
    systemctl --user restart polybar.service
  '';
}
