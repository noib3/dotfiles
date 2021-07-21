let
  colors = import ./palette.nix;
in
{
  primary = {
    foreground = colors.normal.white;
    background = colors.normal.black;
  };

  cursor = {
    text = colors.bright.black;
    cursor = colors.normal.white;
  };

  selection = {
    text = colors.normal.white;
    background = colors.bright.black;
  };

  normal = colors.normal;
  bright = colors.bright;
}
