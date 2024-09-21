{
  lib,
  colorscheme,
  palette,
}:

let
  c = {
    "afterglow" = {
      border = {
        unfocused = lib.hex.scale 220 palette.normal.black;
        focused = lib.hex.scale 95 palette.normal.white;
      };
    };
  };
in
{
  border = {
    unfocused = c.${colorscheme}.border.unfocused or palette.bright.black;
    focused = c.${colorscheme}.border.unfocused or (lib.hex.scale 130 palette.bright.white);
  };
}
