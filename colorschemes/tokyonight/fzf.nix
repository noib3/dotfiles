let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  current-line.bg = hexlib.scale 75 colors.bright.black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = "#565f89";
}
