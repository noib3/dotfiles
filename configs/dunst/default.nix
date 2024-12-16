{
  colorscheme,
  font-family,
  palette,
  hexlib,
  hicolor-icon-theme,
}:

let
  colors = import ./colors.nix { inherit colorscheme palette hexlib; };
  font = import ./font.nix { family = font-family; };
in
{
  iconTheme = {
    package = hicolor-icon-theme;
    name = "hicolor";
    size = "scalable";
  };

  settings = {
    global = {
      font = "${font-family} ${toString font.size}";
      geometry = "375x0-45+40";
      frame_width = "2";
      frame_color = "${colors.border}";
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
