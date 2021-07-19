let
  colors = import ./palette.nix;
  half-black = "#0d0d0d";
  ninety-percent-blue = "#618aa8";
in
rec {
  normal = {
    fg = colors.normal.white;
    bg = half-black;
  };

  prompt = normal;

  selected = {
    fg = colors.normal.white;
    bg = colors.normal.black;
  };

  highlight.fg = ninety-percent-blue;
}
