let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  current-line.bg = hexlib.scale 90 colors.bright.black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = hexlib.scale 130 colors.bright.black;
}
