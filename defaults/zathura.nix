{ font, colors }:

{
  options = {
    font = "${font.family} ${font.style} ${font.size}";
    default-bg = colors.bg;
    default-fg = colors.fg;
  };
}
