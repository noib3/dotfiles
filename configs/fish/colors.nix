{ colorscheme, palette }:

let
  hexlib = import ../../palettes/hexlib.nix;
  c = {
    "nord" = {
      autosuggestion = hexlib.scale 0.5 palette.normal.white;
      comment = hexlib.scale 0.5 palette.normal.white;
    };
  };
in
{
  autosuggestion = c.${colorscheme}.autosuggestion or palette.bright.white;
  comment = c.${colorscheme}.comment or palette.bright.white;
  param = palette.normal.cyan;
  operator = palette.normal.cyan;
  end = palette.normal.cyan;
  selection_bg = palette.bright.black;
}
