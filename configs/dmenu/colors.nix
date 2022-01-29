{ colorscheme, palette }:

let
  hexlib = import ../../palettes/hexlib.nix;

  c = {
    "afterglow" = {
      prompt.fg = palette.normal.magenta;
      highlight.fg = hexlib.scale 0.9 palette.normal.blue;
      selected.bg = hexlib.scale 1.25 palette.normal.black;
    };
    "onedark" = {
      highlight.fg = hexlib.scale 0.9 palette.normal.blue;
    };
  };
in
rec {
  normal.fg = palette.normal.white;
  normal.bg = hexlib.scale 0.5 palette.normal.black;

  prompt.fg = c.${colorscheme}.prompt.fg or normal.fg;
  prompt.bg = c.${colorscheme}.prompt.bg or normal.bg;

  selected.fg = c.${colorscheme}.selected.fg or palette.normal.white;
  selected.bg = c.${colorscheme}.selected.bg or palette.normal.black;

  highlight.fg = c.${colorscheme}.highlight.fg or palette.bright.cyan;
}
