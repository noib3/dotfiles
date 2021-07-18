let
  colors = import ./palette.nix;
in
{
  current-line.bg = colors.bright.black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = colors.bright.white;
}
