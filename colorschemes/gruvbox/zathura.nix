let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix { };
in
{
  default.bg = colors.normal.black;
  default.fg = colors.normal.white;

  inputbar.bg = colors.bright.black;
  inputbar.fg = hexlib.scale 130 colors.bright.white;

  highlight.bg = colors.normal.blue;
}
