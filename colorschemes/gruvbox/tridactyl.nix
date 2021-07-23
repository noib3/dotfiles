let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix { };
in
{
  hints = {
    bg = colors.bright.black;
    fg = hexlib.scale 130 colors.bright.white;
  };
  commandline = {
    bg = colors.bright.black;
    fg = colors.normal.white;
  };
}
