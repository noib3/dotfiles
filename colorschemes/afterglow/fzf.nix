let
  colors = import ./palette.nix;
  onehundredtwenty-percent-black = "#282828";
in
{
  current-line.bg = onehundredtwenty-percent-black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = colors.bright.white;
}
