let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  autosuggestion = hexlib.scale 50 colors.normal.white;
  comment = hexlib.scale 50 colors.normal.white;
  param = colors.normal.cyan;
  operator = colors.normal.cyan;
  end = colors.normal.cyan;
  selection-bg = colors.bright.black;
}
