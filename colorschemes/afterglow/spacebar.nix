let
  colors = import ./palette.nix;
in
{
  fg = colors.normal.white;
  bg = colors.bright.black;
  focused-workspace.fg = colors.normal.yellow;
}
