let
  colors = import ./palette.nix;
in
{
  inherit (colors.normal) black red green yellow blue magenta cyan;
  orange = colors.bright.yellow;
  gray = colors.bright.white;
}
