let
  colors = import ./palette.nix;
in
{
  fg = colors.bright.white;
  bg = colors.bright.black;
  focused-workspace.fg = colors.bright.yellow;
}
