let
  colors = import ./palette.nix;
in
{
  border = {
    unfocused = colors.bright.black;
    focused = colors.primary.foreground;
  };
}
