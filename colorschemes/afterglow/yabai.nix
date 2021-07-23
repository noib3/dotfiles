let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  border = {
    unfocused = hexlib.scale 220 colors.normal.black;
    focused = hexlib.scale 95 colors.normal.white;
  };
}
