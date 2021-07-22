let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix { };
in
rec {
  normal = {
    fg = colors.normal.white;
    bg = hexlib.scale 50 colors.normal.black;
  };

  prompt = normal;

  selected = {
    fg = colors.normal.white;
    bg = colors.normal.black;
  };

  highlight.fg = hexlib.scale 90 colors.normal.blue;
}
