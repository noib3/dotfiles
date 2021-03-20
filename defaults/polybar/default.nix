{ font, colors }:

{
  config = {
    "bar/bar" = {
      width = 1872;
      height = 25;
      offset-y = 20;
      offset-x = 24;
      padding-right = 1;
      module-margin = 1;
      radius = 0;
      cursor-click = "pointer";
      border-size = 2;
      border-color = colors.border;
      font-0 = "${font.family}:style=${font.style}:size=${font.size};3";
      font-1 = "Noto Color Emoji:style=Regular:scale=9;2";
      background = colors.bg;
      foreground = colors.fg;
      wm-restack = "bspwm";
      modules-left = "bspwm";
      modules-right = "battery date";
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

    "module/battery" = {
      type = "internal/battery";
      battery = "BAT0";
      adapter = "AC0";
      poll-interval = 1;
      label-charging = "🔌 %percentage%%";
      label-discharging = "🔋 %percentage%%";
      label-full = "🔌 %percentage%%";
    };

    "module/date" = {
      type = "internal/date";
      internal = 5;
      date = "%a, %B %d";
      time = "%R";
      label = "📆 %date%  🕑 %time%";
    };
  };

  script = "";
  # script = "polybar bar &";
}
