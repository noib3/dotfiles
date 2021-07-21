let
  colors = import ./palette.nix;
in
rec {
  border = colors.bright.white;

  urgency-normal = {
    bg = colors.bright.black;
    fg = colors.bright.white;
  };

  urgency-low = urgency-normal;
  urgency-critical = urgency-normal;
}
