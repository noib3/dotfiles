let
  colors = import ./palette.nix;
  half-black = "#14161a";
  ninety-percent-blue = "#579dd7";
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
