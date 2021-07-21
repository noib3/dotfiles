let
  colors = import ./palette.nix;
  ninetysix-percent-white = "#b9b9b9";
in
rec {
  border = ninetysix-percent-white;

  urgency-normal = {
    bg = colors.normal.black;
    fg = colors.normal.white;
  };

  urgency-low = urgency-normal;
  urgency-critical = urgency-normal;
}
