{ font, colors }:
let
  f0 = {
    family = font.font-0.family;
    style = font.font-0.style;
    size = builtins.toString font.font-0.size;
    padding-top = builtins.toString font.font-0.padding-top;
  };

  f2 = {
    family = font.font-2.family;
    style = font.font-2.style;
    size = builtins.toString font.font-2.size;
    padding-top = builtins.toString font.font-2.padding-top;
  };

  f3 = {
    family = font.font-3.family;
    style = font.font-3.style;
    size = builtins.toString font.font-3.size;
    padding-top = builtins.toString font.font-3.padding-top;
  };
in
{
  config = {
    "settings" = {
      format-background = colors.module.bg;
    };

    "bar/bar" = {
      height = 25;
      module-margin-left = 1;
      radius = 0;
      enable-ipc = true;
      cursor-click = "pointer";
      font-0 = "${f0.family}:style=${f0.style}:size=${f0.size};${f0.padding-top}";
      font-1 = "Noto Color Emoji:style=Regular:scale=9;3";
      font-2 = "${f2.family}:style=${f2.style}:size=${f2.size};${f2.padding-top}";
      font-3 = "${f3.family}:style=${f3.style}:size=${f3.size};${f3.padding-top}";
      background = colors.bar.bg;
      foreground = colors.bar.fg;
      wm-restack = "bspwm";
      modules-left = "bspwm";
      modules-right = "bluetooth wifi ethernet battery date time";
    };

    "module/bspwm" = {
      type = "internal/bspwm";
      ws-icon-0 = "1;1";
      ws-icon-1 = "2;2";
      ws-icon-2 = "3;3";
      ws-icon-3 = "4;4";
      ws-icon-4 = "5;5";
      ws-icon-5 = "videos;%{T4}%{T-}";
      format-background = colors.bar.bg;
      label-focused = "%icon%";
      label-focused-padding = 1;
      label-focused-background = colors.bspwm.focused.bg;
      label-occupied = "%icon%";
      label-occupied-padding = 1;
      label-occupied-foreground = colors.bspwm.occupied.fg;
      label-urgent = "%icon%!";
      label-urgent-padding = 1;
      label-empty = "%icon%";
      label-empty-padding = 1;
      label-empty-foreground = colors.bspwm.empty.fg;
      label-focused-empty = "%icon%";
      label-focused-empty-padding = 1;
      label-focused-empty-background = colors.bspwm.focused.bg;
      label-focused-empty-foreground = colors.bspwm.empty.fg;
    };

    "module/time" = {
      type = "internal/date";
      format-padding = 1;
      interval = 5;
      time = "%R";
      label = "🕑 %time%";
    };

    "module/date" = {
      type = "internal/date";
      format-padding = 1;
      interval = 5;
      date = "%a, %B %d";
      label = "📆 %date%";
    };

    "module/battery" = {
      type = "internal/battery";
      format-charging-padding = 1;
      format-discharging-padding = 1;
      format-full-padding = 1;
      battery = "BAT0";
      adapter = "AC0";
      poll-interval = 1;
      label-charging = "🔌 %percentage%%";
      label-discharging = "🔋 %percentage%%";
      label-full = "🔌 %percentage%%";
    };

    "module/ethernet" = {
      type = "internal/network";
      format-connected-padding = 1;
      format-disconnected-padding = 1;
      format-packetloss-padding = 1;
      interface = "enp2s0";
      ping-interval = 3;
      label-connected = "%{F${colors.icons.ethernet.fg}}%{T3}%{T-}%{F-}";
    };

    "module/wifi" = {
      type = "internal/network";
      format-connected-padding = 1;
      format-disconnected-padding = 1;
      format-packetloss-padding = 1;
      interface = "wlo1";
      ping-interval = 3;
      label-connected = "%{F${colors.icons.wifi.on.fg}}%{T4}直%{T-}%{F-} %essid%";
      label-disconnected = "%{F${colors.icons.wifi.off.fg}}%{T4}睊%{T-}%{F-}";
      click-left = "dmenu-wifi &";
    };

    "module/bluetooth" = {
      type = "custom/script";
      format-padding = 1;
      exec = "dmenu-bluetooth --status";
      interval = 1;
      click-left = "dmenu-bluetooth &";
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
