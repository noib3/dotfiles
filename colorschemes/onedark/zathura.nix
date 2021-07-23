let
  colors = import ./palette.nix;
in
{
  default = {
    bg = colors.normal.black;
    fg = colors.normal.white;
  };

  inputbar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
  };

  highlight.bg = colors.normal.yellow;
}
