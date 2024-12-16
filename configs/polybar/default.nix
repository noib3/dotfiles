{
  colorscheme,
  font-family,
  palette,
  hexlib,
  concatStringsSep,
}:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };
  font = import ./font.nix { family = font-family; };

  T1 = font.text;
  T2 = font.icons.default;
  T3 = font.icons.videos;
  T4 = font.icons.bluetooth;
  T5 = font.icons.wifi;
  T6 = font.icons.battery;
  T7 = font.icons.calendar;
  T8 = font.icons.menu;
in
{
  settings = {
    "bar/bar" = {
      height = 25;
      enable-ipc = true;
      cursor-click = "pointer";
      override-redirect = true;

      # Let Polybar be displayed under fullscreen windows
      wm-restack = "bspwm";

      font = [
        "${T1.family}:style=${T1.style}:size=${builtins.toString T1.size};${builtins.toString T1.padding-top}"
        "${T2.family}:style=${T2.style}:size=${builtins.toString T2.size};${builtins.toString T2.padding-top}"
        "${T3.family}:style=${T3.style}:size=${builtins.toString T3.size};${builtins.toString T3.padding-top}"
        "${T4.family}:style=${T4.style}:size=${builtins.toString T4.size};${builtins.toString T4.padding-top}"
        "${T5.family}:style=${T5.style}:size=${builtins.toString T5.size};${builtins.toString T5.padding-top}"
        "${T6.family}:style=${T6.style}:size=${builtins.toString T6.size};${builtins.toString T6.padding-top}"
        "${T7.family}:style=${T7.style}:size=${builtins.toString T7.size};${builtins.toString T7.padding-top}"
        "${T8.family}:style=${T8.style}:size=${builtins.toString T8.size};${builtins.toString T8.padding-top}"
      ];
      foreground = colors.bar.fg;
      background = colors.bar.bg;

      modules.left = concatStringsSep " " [
        "workspaces"
        "window"
      ];

      modules.right = concatStringsSep " " [
        # "bluetooth"
        "wifi"
        "ethernet"
        "battery"
        "datetime"
      ];
    };

    "module/power" = {
      type = "custom/text";
      content = {
        text = "%{T2}%{T-}";
        padding = 1;
        foreground = colors.power.icon;
      };
      click.left = "dmenu-powermenu";
    };

    "module/workspaces" = {
      type = "internal/bspwm";
      ws.icon = [
        "1;1"
        "2;2"
        "3;3"
        "4;4"
        "5;5"
        "videos;%{T3}%{T-}"
      ];
      label.focused = {
        text = "%icon%";
        padding = 1;
        foreground = colors.workspaces.focused.fg;
        background = colors.workspaces.focused.bg;
      };
      label.occupied = {
        text = "%icon%";
        padding = 1;
        foreground = colors.workspaces.occupied.fg;
      };
      label.empty = {
        text = "%icon%";
        padding = 1;
        foreground = colors.workspaces.empty.fg;
      };
      label.focused.empty = {
        text = "%icon%";
        padding = 1;
        foreground = colors.workspaces.empty.fg;
        background = colors.workspaces.focused.bg;
      };
      label.urgent = {
        text = "!%icon%";
        padding = 1;
      };
    };

    "module/window" = {
      type = "internal/xwindow";
      label.text = "%title:0:65:…%";
      label.padding = 1;
    };

    "module/bluetooth" = {
      type = "custom/script";
      exec = "POWER_ON_FG=${colors.bluetooth.icon.on} POWER_OFF_FG=${colors.bluetooth.icon.off} CONNECTED_FG=${colors.bluetooth.icon.connected} dmenu-bluetooth --status";
      interval = 1;
      click.left = "dmenu-bluetooth &";
      label.padding = 1;
    };

    "module/wifi" = {
      type = "internal/network";
      interface = "wlo1";
      ping-interval = 3;
      label.connected = {
        text = "%essid%";
        foreground = colors.bar.fg;
      };
      format.connected = {
        text = "%{A1:dmenu-wifi &:}%{T5}%{T-} <label-connected>%{A}";
        padding = 1;
        foreground = colors.wifi.icon.on;
      };
      format.disconnected = {
        text = "%{A1:dmenu-wifi &:}%{T5}睊%{T-}%{A}";
        padding = 1;
        foreground = colors.wifi.icon.off;
      };
      format.packetloss = {
        text = "%{A1:dmenu-wifi &:}%{T5}%{T-} <label-connected>%{A}";
        padding = 1;
        foreground = colors.wifi.icon.on;
      };
    };

    "module/ethernet" = {
      type = "internal/network";
      interface = "enp2s0";
      ping-interval = 3;
      label.connected = {
        text = "";
        padding = 1;
        foreground = colors.ethernet.icon;
      };
    };

    "module/volume" = {
      type = "internal/pulseaudio";
      use-ui-max = true;
      label.volume = {
        text = "%percentage%%";
        foreground = colors.bar.fg;
      };
      format.volume = {
        text = "%{T2}<ramp-volume>%{T-} <label-volume>";
        padding = 1;
        foreground = colors.ethernet.icon;
      };
      format.muted = {
        text = "%{T2}婢%{T-}";
        padding = 1;
        foreground = colors.wifi.icon.off;
      };
      ramp-volume = [
        "奄"
        "奔"
        "墳"
      ];
    };

    "module/battery" = rec {
      type = "internal/battery";
      battery = "BAT0";
      adapter = "AC0";
      poll-interval = 1;
      label.charging = {
        text = "%percentage%%";
        foreground = colors.bar.fg;
      };
      label.discharging = label.charging;
      label.full = label.charging;
      format.charging = {
        text = "ﮣ <label-charging>";
        padding = 1;
        foreground = colors.battery.icon.charging;
      };
      format.discharging = {
        text = "<ramp-capacity><label-discharging>";
        padding = 1;
      };
      format.full = {
        text = "%{T6}ﮣ%{T-} <label-full>";
        padding = 1;
        foreground = colors.battery.icon.charging;
      };
      ramp-capacity.text = [
        "  "
        "  "
        "  "
        "  "
        "  "
      ];
      ramp-capacity.foreground = colors.battery.icon.ok;
      ramp-capacity-0.foreground = colors.battery.icon.dying;
      ramp-capacity-1.foreground = colors.battery.icon.low;
    };

    "module/datetime" = {
      type = "internal/date";
      time = "%a, %B %d, %R";
      interval = 5;
      label = {
        text = "%time%";
        foreground = colors.bar.fg;
      };
      format = {
        text = "%{T7}ﭷ%{T-} <label>";
        padding = 1;
        foreground = colors.datetime.icon;
      };
    };

    "module/notification-center" = {
      type = "custom/text";
      content = {
        text = "%{T8}%{T-}";
        padding = 1;
        foreground = colors.notification-center.icon;
      };
      click.left = "true";
    };
  };

  script = ''
    PATH=$PATH:\
    /run/wrappers/bin:\
    /home/noib3/.nix-profile/bin:\
    /etc/profiles/per-user/noib3/bin:\
    /nix/var/nix/profiles/default/bin:/run/current-system/sw/bin polybar bar &
  '';
}
