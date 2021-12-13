let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  current-line.bg = hexlib.scale 150 colors.normal.black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = hexlib.scale 85 colors.bright.white;
}
