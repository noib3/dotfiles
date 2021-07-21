let
  colors = import ./palette.nix;
  hints = "#b57614";
in
{
  hints.fg = colors.normal.white;
  hints.bg = hints;
  commandline.fg = colors.normal.white;
  commandline.bg = colors.normal.black;
}
