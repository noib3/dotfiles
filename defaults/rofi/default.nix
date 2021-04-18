{ pkgs, font, colors }:

{
  font = "${font.family} ${font.style} ${font.size}";
  scrollbar = false;
  cycle = false;

  padding = 300;
  terminal = "${pkgs.alacritty}/bin/alacritty";
  fullscreen = true;

  colors = {
    window = {
      background = "#282c34";
      border = "argb:582a373e";
      separator = "#c3c6c8";
    };

    rows = {
      normal = {
        background = "argb:58455a64";
        foreground = "#fafbfc";
        backgroundAlt = "argb:58455a64";
        highlight = {
          background = "#00bcd4";
          foreground = "#fafbfc";
        };
      };
    };
  };
}
