let
  colors = import ./palette.nix;
in
{
  autosuggestion = colors.bright.white;
  comment = colors.bright.white;
  param = colors.normal.cyan;
  operator = colors.normal.cyan;
  end = colors.normal.cyan;
  selection-bg = colors.bright.black;
}
