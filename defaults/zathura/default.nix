{ font, colors }:

{
  options = {
    font = "${font.family} ${font.style} ${font.size}";

    default-bg = colors.default.bg;
    default-fg = colors.default.fg;

    inputbar-bg = colors.inputbar.bg;
    inputbar-fg = colors.inputbar.fg;

    highlight-color = colors.highlight.bg;

    guioptions = "";
    selection-clipboard = "clipboard";
    highlight-transparency = "0.40";
  };
}
