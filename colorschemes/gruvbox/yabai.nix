let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix { };
in
{
  border = {
    unfocused = colors.bright.black;
    focused = hexlib.scale 130 colors.bright.white;
  };
}
