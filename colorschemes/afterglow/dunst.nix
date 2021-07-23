let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
rec {
  border = hexlib.scale 95 colors.normal.white;

  urgency-normal = {
    bg = colors.normal.black;
    fg = colors.normal.white;
  };

  urgency-low = urgency-normal;
  urgency-critical = urgency-normal;
}
