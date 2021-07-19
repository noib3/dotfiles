let
  colors = import ./palette.nix;
  onehundredtwenty-percent-bright-black = "#242424";
in
{
  current-line.bg = onehundredtwenty-percent-bright-black;
  border = colors.bright.black;
  directories = colors.normal.blue;
  grayed-out-directories = colors.bright.white;
}
