let
  colors = import ./palette.nix;
  ninetysix-percent-white = "#b9b9b9";
in
{
  border = {
    unfocused = "#393939";
    focused = ninetysix-percent-white;
  };
}
