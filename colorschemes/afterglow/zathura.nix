let
  colors = import ./palette.nix;
in
{
  default.bg = colors.normal.black;
  default.fg = colors.normal.white;

  inputbar.bg = colors.bright.black;
  inputbar.fg = colors.normal.white;

  highlight.bg = colors.normal.cyan;
}
