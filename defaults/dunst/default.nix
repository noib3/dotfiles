{ font, colors }:

{
  settings = {
    global = {
      font = "${font.family} ${font.size}";
      geometry = "375x0-14+41";
      icon_position = "left";
      max_icon_size = "50";
      horizontal_padding = 10;
      markup = "full";
      format = "<b>%a</b>\\n%s\\n%b";
      word_wrap = false;
      ellipsize = "end";
      ignore_newline = false;
    };

    urgency_low = {
      background = colors.urgency-low.bg;
      foreground = colors.urgency-low.fg;
    };

    urgency_normal = {
      background = colors.urgency-normal.bg;
      foreground = colors.urgency-normal.fg;
    };

    urgency_critical = {
      background = colors.urgency-critical.bg;
      foreground = colors.urgency-critical.fg;
    };
  };
}
