let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
rec {
  normal = {
    fg = colors.normal.white;
    bg = hexlib.scale 50 colors.normal.black;
  };

  prompt = {
    fg = colors.normal.magenta;
    bg = normal.bg;
  };

  selected = {
    fg = colors.normal.white;
    bg = hexlib.scale 125 colors.normal.black;
  };

  highlight.fg = hexlib.scale 90 colors.normal.blue;
}
