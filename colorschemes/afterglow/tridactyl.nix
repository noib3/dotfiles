let
  colors = import ./palette.nix;
in
{
  hints = {
    bg = colors.bright.black;
    fg = colors.normal.white;
  };
  commandline = {
    bg = colors.normal.black;
    fg = colors.normal.white;
  };
}
