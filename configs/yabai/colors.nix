{ colorscheme, palette, hexlib }:

let
  c = {
    "afterglow" = {
      border = {
        unfocused = hexlib.scale 220 palette.normal.black;
        focused = hexlib.scale 95 palette.normal.white;
      };
    };
  };
in
{
  border = {
    unfocused = c.${colorscheme}.border.unfocused or palette.bright.black;
    focused =
      c.${colorscheme}.border.unfocused
        or (hexlib.scale 130 palette.bright.white);
  };
}
