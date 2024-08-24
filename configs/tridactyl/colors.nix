{ colorscheme
, palette
}:

let
  hexlib = import ../../colorschemes/hexlib.nix;

  c = {
    "afterglow" = {
      hints.fg = palette.normal.white;
      commandline.bg = palette.normal.black;
    };
  };
in
{
  hints = {
    bg = palette.bright.black;
    fg = c.${colorscheme}.hints.fg or (hexlib.scale 130 palette.bright.white);
  };
  commandline = {
    bg = c.${colorscheme}.commandline.bg or palette.bright.black;
    fg = palette.normal.white;
  };
}
