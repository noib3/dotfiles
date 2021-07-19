let
  colors = import ./palette.nix;
in
{
  hints.fg = colors.normal.white;
  hints.bg = colors.bright.black;
  commandline.fg = colors.normal.white;
  commandline.bg = colors.normal.black;
}
