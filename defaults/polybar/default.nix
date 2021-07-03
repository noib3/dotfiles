{ lib, fonts, colors }:

let
  T1 = fonts.main;
  T2 = fonts.icons;
in
{
  settings = {
    "bar/bar" = {
      height = 25;
      enable-ipc = true;
      cursor-click = "pointer";

      # Make Polybar go under other windows when going fullscreen
      wm-restack = "bspwm";

      background = colors.bar.bg;
      foreground = colors.bar.fg;
      font = [
        "${T1.family}:style=${T1.style}:size=${T1.size};${T1.padding-top}"
        "${T2.family}:style=${T2.style}:size=${T2.size};${T2.padding-top}"
      ];

      modules.left = lib.concatStringsSep " " [
        "sysinfos"
        "workspaces"
        "window"
      ];

      modules.right = lib.concatStringsSep " " [
        "bluetooth"
        "wifi"
        "ethernet"
        "battery"
        "datetime"
        "notification-center"
      ];
    };

    "module/sysinfos" = {
      type = "custom/text";
      content = {
        text = "%{T2}%{T-}";
        padding = 1;
        foreground = colors.modules.sysinfos.icon;
        background = colors.modules.sysinfos.bg;
      };
    };

    "module/workspaces" = {
      type = "internal/bspwm";
      ws.icon = [
        "1;1"
        "2;2"
        "3;3"
        "4;4"
        "5;5"
        "videos;%{T2}%{T-}"
      ];
      label.focused = {
        text = "%icon%";
        padding = 1;
        foreground = colors.modules.workspaces.focused.fg;
      };
      label.occupied = {
        text = "%icon%";
        padding = 1;
        foreground = colors.modules.workspaces.occupied.fg;
      };
      label.empty = {
        text = "%icon%";
        padding = 1;
        foreground = colors.modules.workspaces.empty.fg;
      };
      label.focused.empty = {
        text = "%icon%";
        padding = 1;
        foreground = colors.modules.workspaces.focused.empty.fg;
      };
      label.urgent = {
        text = "!%icon%";
        padding = 1;
      };
      format.background = colors.modules.workspaces.bg;
    };

    "module/window" = {
      type = "internal/xwindow";
      label.text = "%title%";
      label.padding = 1;
    };

    "module/bluetooth" = {
      type = "custom/script";
      exec = "dmenu-bluetooth --status";
      interval = 1;
      click.left = "dmenu-bluetooth &";
      label.padding = 1;
      format.background = colors.modules.bluetooth.bg;
    };

    "module/wifi" = {
      type = "internal/network";
      interface = "wlo1";
      ping-interval = 3;
      click.left = "dmenu-wifi &";
      label.connected = {
        text = "%essid%";
        foreground = colors.bar.fg;
      };
      label.disconnected = {
        text = "";
        foreground = colors.bar.fg;
      };
      format.connected = {
        text = "%{T2}直%{T-} <label-connected>";
        padding = 1;
        foreground = colors.modules.wifi.on.icon;
        background = colors.modules.wifi.bg;
      };
      format.disconnected = {
        text = "%{T2}睊%{T-} <label-disconnected>";
        padding = 1;
        foreground = colors.modules.wifi.off.icon;
        background = colors.modules.wifi.bg;
      };
    };

    "module/ethernet" = {
      type = "internal/network";
      interface = "enp2s0";
      ping-interval = 3;
      label.connected = {
        text = "";
        padding = 1;
        foreground = colors.modules.ethernet.icon;
        background = colors.modules.ethernet.bg;
      };
    };

    "module/battery" = {
      type = "internal/battery";
      battery = "BAT0";
      adapter = "AC0";
      poll-interval = 1;
      label.charging = {
        text = "%percentage%%";
        foreground = colors.bar.fg;
      };
      label.discharging = {
        text = "%percentage%%";
        foreground = colors.bar.fg;
      };
      label.full = {
        text = "%percentage%%";
        foreground = colors.bar.fg;
      };
      format.charging = {
        text = " <label-charging>";
        padding = 1;
        foreground = colors.modules.battery.charging.icon;
        background = colors.modules.battery.bg;
      };
      format.discharging = {
        text = "<ramp-capacity><label-discharging>";
        padding = 1;
        background = colors.modules.battery.bg;
      };
      format.full = {
        text = " <label-full>";
        padding = 1;
        foreground = colors.modules.battery.full.icon;
        background = colors.modules.battery.bg;
      };
      ramp-capacity.text = [
        "  "
        "  "
        "  "
        "  "
        "  "
      ];
      ramp-capacity.foreground = colors.modules.battery.ok.icon;
      ramp-capacity-0.foreground = colors.modules.battery.dying.icon;
      ramp-capacity-1.foreground = colors.modules.battery.low.icon;
    };

    "module/datetime" = {
      type = "internal/date";
      time = "%a %B %d, %R";
      interval = 5;
      label = {
        text = "%time%";
        foreground = colors.bar.fg;
      };
      format = {
        text = "%{T2}ﭷ%{T-} <label>";
        padding = 1;
        foreground = colors.modules.datetime.icon;
        background = colors.modules.datetime.bg;
      };
    };

    "module/notification-center" = {
      type = "custom/text";
      content = {
        text = "%{T2}%{T-}";
        padding = 1;
        foreground = colors.modules.notification-center.icon;
        background = colors.modules.notification-center.bg;
      };
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
