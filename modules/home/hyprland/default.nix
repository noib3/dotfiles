{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.hyprland;
  inherit (config.modules.colorscheme) palette;
in
{
  options.modules.hyprland = {
    enable = mkEnableOption "Hyprland";
  };

  config = mkIf cfg.enable {
    home.pointerCursor.hyprcursor = {
      enable = true;
      size = config.home.pointerCursor.size;
    };

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        monitor = ",preferred,auto,auto";

        env = [
          "HYPRCURSOR_SIZE,25"
          "XCURSOR_SIZE,25"
        ];

        general = {
          allow_tearing = false;
          border_size = 2;
          "col.active_border" = "rgb(${lib.strings.removePrefix "#" palette.normal.white})";
          "col.inactive_border" = "rgb(${lib.strings.removePrefix "#" palette.bright.black})";
          gaps_in = 10;
          gaps_out = 25;
          layout = "dwindle";
          resize_on_border = true;
        };

        decoration = {
          rounding = 0;

          # Change transparency of focused and unfocused windows
          active_opacity = 1.0;
          inactive_opacity = 1.0;

          # https://wiki.hyprland.org/Configuring/Variables/#blur
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };

          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };

        # https://easings.net/#easeOutQuint
        bezier = "ease_out_quint, 0.22, 1, 0.36, 1";

        # Disable all animations, except for workspace switching.
        animation = [
          "workspaces, 1, 5, ease_out_quint, slide"
          "windows, 0"
          "layers, 0"
          "fade, 0"
          "border, 0"
          "borderangle, 0"
        ];

        dwindle = {
          force_split = 2;
        };

        # https://wiki.hyprland.org/Configuring/Variables/#misc
        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        # https://wiki.hyprland.org/Configuring/Variables/#input
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";

          # Don't automatically focus hovered windows.
          follow_mouse = 0;

          # Start repeating a key after holding it down for these many
          # milliseconds.
          repeat_delay = 200;

          # While repeating a key, fire a new event every these many
          # milliseconds.
          repeat_rate = 30;

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

          touchpad = {
            natural_scroll = true;
          };
        };

        # https://wiki.hyprland.org/Configuring/Variables/#gestures
        gesture = "4, horizontal, workspace";

        # Example per-device config
        # See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
        device = {
          name = "epic-mouse-v1";
          sensitivity = -0.5;
        };

        # ********** Key Bindings **********
        # See https://wiki.hyprland.org/Configuring/Binds/ for more.

        "$launcher" = "fuzzel";
        # "$browser" = "${lib.getExe config.modules.browser.package}";
        "$browser" = "qutebrowser";
        "$terminal" = "${lib.getExe config.modules.terminal.package}";

        bind = [
          # Launch programs.
          "SUPER, Space, exec, $launcher"
          "ALT, W, exec, $browser"
          "SUPER, Return, exec, $terminal"
          # Quit current program.
          "SUPER, Q, killactive"
          # Toggle fullscreen.
          "ALT, F, fullscreen"
          # Focus windows.
          "ALT, up, movefocus, u"
          "ALT, down, movefocus, d"
          "ALT, left, movefocus, l"
          "ALT, right, movefocus, r"
          # Focus workspace by number.
          "ALT, 1, workspace, 1"
          "ALT, 2, workspace, 2"
          "ALT, 3, workspace, 3"
          "ALT, 4, workspace, 4"
          "ALT, 5, workspace, 5"
          "ALT, 6, workspace, 6"
          "ALT, 7, workspace, 7"
          "ALT, 8, workspace, 8"
          # Focus prev/next workspace.
          "CTRL, left, workspace, r-1"
          "CTRL, right, workspace, r+1"
          # Send window to the given desktop.
          "ALT SHIFT, 1, movetoworkspace, 1"
          "ALT SHIFT, 2, movetoworkspace, 2"
          "ALT SHIFT, 3, movetoworkspace, 3"
          "ALT SHIFT, 4, movetoworkspace, 4"
          "ALT SHIFT, 5, movetoworkspace, 5"
          "ALT SHIFT, 6, movetoworkspace, 6"
          "ALT SHIFT, 7, movetoworkspace, 7"
          "ALT SHIFT, 8, movetoworkspace, 8"
          # Screenshot the whole screen or a portion of it.
          "SUPER SHIFT, 3, exec, grimblast save output ~/screenshots/$(date +\"%F@%T.png\")"
          "SUPER SHIFT, 4, exec, grimblast save area ~/screenshots/$(date +\"%F@%T.png\")"
          # Quit Hyprland.
          "SUPER, M, exit"
        ];

        # Volume.
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6.25%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 6.25%-"
        ];

        # Media.
        bindl = [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86AudioNext, exec, playerctl next"
        ];

        windowrulev2 = "suppressevent maximize, class:.*";

        # Xwayland can't handle scaling properly. Small is better than blurry.
        xwayland = {
          force_zero_scaling = true;
        };
      };
    };
  };
}
