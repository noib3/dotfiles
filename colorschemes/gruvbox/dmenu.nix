let
  colors = import ./palette.nix;
  half-black = "#141414";
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

  highlight.fg = colors.bright.cyan;
}
