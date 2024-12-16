{
  config,
  colorscheme,
  palette,
}:

let
  inherit (config.lib.mine) hex;
  c = {
    "afterglow" = {
      border = {
        unfocused = hex.scale 220 palette.normal.black;
        focused = hex.scale 95 palette.normal.white;
      };
    };
  };
in
{
  border = {
    unfocused = c.${colorscheme}.border.unfocused or palette.bright.black;
    focused =
      c.${colorscheme}.border.unfocused or (hex.scale 130 palette.bright.white);
  };
}
