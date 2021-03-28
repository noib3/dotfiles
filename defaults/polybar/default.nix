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
    };

    "bar/bar" = {
      height = 25;
      module-margin-left = 1;
      radius = 0;
      cursor-click = "pointer";
      font-0 = "${font.family}:style=${font.style}:size=${font.size};3";
      font-1 = "Noto Color Emoji:style=Regular:scale=9;2";
      background = colors.bg;
      foreground = colors.fg;
      underline-size = 2;
      wm-restack = "bspwm";
      modules-left = "bspwm";
      modules-right = "rofi-bluetooth wireless-network wired-network pulseaudio battery date time";
    };

    "module/bspwm" = {
      type = "internal/bspwm";
      format-background = colors.bg;
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

    "module/pulseaudio" = {
      type = "internal/pulseaudio";
      format-volume-padding = 1;
      format-muted-padding = 1;
      sink = "bluez_sink.5C_44_3E_31_27_86.a2dp_sink";
      use-ui-max = false;
      format-volume = "<ramp-volume> <label-volume>";
      ramp-volume-0 = "🔈";
      ramp-volume-1 = "🔉";
      ramp-volume-2 = "🔊";
      label-muted = "🔇 %percentage%";
    };

    "module/wired-network" = {
      type = "internal/network";
      format-connected-padding = 1;
      format-disconnected-padding = 1;
      format-packetloss-padding = 1;
      interface = "enp2s0";
      ping-interval = 3;
      label-connected = "%{F${colors.wired-network-icon-fg}}%{F-} %ifname%";
      label-disconnected = " %ifname%";
    };

    "module/wireless-network" = {
      type = "internal/network";
      format-connected-padding = 1;
      format-disconnected-padding = 1;
      format-packetloss-padding = 1;
      interface = "wlo1";
      ping-interval = 3;
      label-connected = "%{F${colors.wireless-network-icon-fg}}直%{F-} %essid%";
      label-disconnected = "睊 %ifname%";
    };

    "module/rofi-bluetooth" = {
      type = "custom/script";
      format-padding = 1;
      exec = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth --status";
      interval = 1;
      click-left = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth &";
    };
  };

  script = "";
}
