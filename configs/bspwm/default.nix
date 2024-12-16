{
  pkgs,
  colorscheme,
  palette,
  hexlib,
}:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };

  mpv-focus-prev =
    with pkgs;
    writeShellApplication {
      name = "mpv-focus-prev";
      runtimeInputs = [
        bspwm
        xdo
      ];
      text = (builtins.readFile ./scripts/mpv-focus-prev.sh);
    };

  bspwm-external-rules =
    with pkgs;
    writeShellApplication {
      name = "bspwm-external-rules";
      runtimeInputs = [
        xtitle
      ];
      text = (builtins.readFile ./scripts/bspwm-external-rules.sh);
    };
in
{
  settings = {
    "window_gap" = 28;
    "top_padding" = 15;
    "border_width" = 2;
    "focus_follows_pointer" = true;
    "normal_border_color" = colors.border.unfocused;
    "active_border_color" = colors.border.unfocused;
    "focused_border_color" = colors.border.focused;
    "external_rules_command" = "${bspwm-external-rules}/bin/bspwm-external-rules";
  };

  monitors = {
    "focused" = [
      "1"
      "2"
      "3"
      "4"
      "5"
      "videos"
    ];
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
    "${pkgs.unclutter-xfixes}/bin/unclutter -idle 5"
    "${pkgs.xbanish}/bin/xbanish"
    "${mpv-focus-prev}/bin/mpv-focus-prev"
  ];

  extraConfig = ''
    # Turn off the screen saver (`man xset` for more infos).
    xset s off

    keyctl link @u @s

    systemctl --user start pulseaudio.service
    systemctl --user restart polybar.service
  '';
}
