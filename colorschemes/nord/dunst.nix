let
  colors = import ./palette.nix;
in
rec {
  border = colors.normal.white;

  urgency-normal = {
    bg = colors.normal.black;
    fg = colors.normal.white;
  };

  urgency-low = urgency-normal;
  urgency-critical = urgency-normal;
}
