{ font, colors, scripts-directory }:

{
  config = {
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
      wm-restack = "bspwm";
      modules-left = "bspwm";
      modules-right = "rofi-bluetooth battery date";
    };

    "module/bspwm" = {
      type = "internal/bspwm";
      label-focused = "%name%";
      label-focused-padding = 1;
      label-occupied = "%name%";
      label-occupied-padding = 1;
      label-urgent = "%name%!";
      label-urgent-padding = 1;
      label-empty = "%name%";
      label-empty-padding = 1;
      label-focused-background = colors.focused_desktop_bg;
      label-focused-foreground = colors.focused_desktop_fg;
      label-empty-foreground = colors.empty_desktop_fg;
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

    "module/rofi-bluetooth" = {
      type = "custom/script";
      exec = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth --status";
      interval = 1;
      click-left = "${scripts-directory}/rofi-bluetooth/rofi-bluetooth &";
    };
  };

  script = "";
}
