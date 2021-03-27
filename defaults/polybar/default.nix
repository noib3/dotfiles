{ pkgs ? import <nixpkgs> { }, font, colors, scripts-directory }:

{
  package = pkgs.polybar.override {
    pulseSupport = true;
  };

  config = {
    "colors" = {
      blue = colors.bluetooth-icon-fg;
    };

    "settings" = {
      format-background = colors.focused-desktop-bg;
      format-padding = 1;
    };

    "bar/bar" = {
      height = 25;
      padding-right = 1;
      module-margin = 1;
      radius = 0;
      cursor-click = "pointer";
      font-0 = "${font.family}:style=${font.style}:size=${font.size};3";
      font-1 = "Noto Color Emoji:style=Regular:scale=9;2";
      background = colors.bg;
      foreground = colors.fg;
      underline-size = 2;
      wm-restack = "bspwm";
      modules-left = "bspwm";
      modules-right = "rofi-bluetooth wireless-network wired-network pulseaudio battery date";
    };

    "module/bspwm" = {
      type = "internal/bspwm";
      format-background = colors.bg;
      format-margin = 0;
      label-focused = "%name%";
      label-focused-padding = 1;
      label-focused-background = colors.focused-desktop-bg;
      label-focused-foreground = colors.focused-desktop-fg;
      label-occupied = "%name%";
      label-occupied-padding = 1;
      label-urgent = "%name%!";
      label-urgent-padding = 1;
      label-empty = "%name%";
      label-empty-padding = 1;
      label-empty-foreground = colors.empty-desktop-fg;
    };

    "module/date" = {
      type = "internal/date";
      internal = 5;
      date = "%a, %B %d";
      time = "%R";
      label = "📆 %date%  🕑 %time%";
    };

    "module/battery" = {
      type = "internal/battery";
      battery = "BAT0";
      adapter = "AC0";
      poll-interval = 1;
      label-charging = "🔌 %percentage%%";
      label-discharging = "🔋 %percentage%%";
      label-full = "🔌 %percentage%%";
    };

    "module/pulseaudio" = {
      type = "internal/pulseaudio";
      sink = "bluez_sink.5C_44_3E_31_27_86.a2dp_sink";
      use-ui-max = false;
      format-volume = "<ramp-volume> <label-volume>";
      ramp-volume-0 = "🔈";
      ramp-volume-1 = "🔉";
      ramp-volume-2 = "🔊";
      label-muted = "🔇 %percentage%";
    };

    "module/rofi-bluetooth" = {
      type = "custom/script";
      exec = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth --status";
      interval = 1;
      click-left = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth &";
    };

    "module/wired-network" = {
      type = "internal/network";
      interface = "enp2s0";
      ping-interval = 3;
      label-connected = "%{F${colors.wired-network-icon-fg}}%{F-} %ifname%";
      label-disconnected = " %ifname%";
    };

    "module/wireless-network" = {
      type = "internal/network";
      interface = "wlo1";
      ping-interval = 3;
      label-connected = "%{F${colors.wireless-network-icon-fg}}直%{F-} %essid%";
      label-disconnected = "睊 %ifname%";
    };
  };

  script = "";
}
