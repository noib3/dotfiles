{
  colorscheme,
  palette,
  hexlib,
}:
let
  c = {
    "afterglow".border = hexlib.scale 0.95 palette.normal.white;
    "gruvbox" = {
      border = palette.bright.white;
      urgency-normal.bg = palette.bright.black;
      urgency-normal.fg = palette.bright.white;
    };
    "tokyonight" = {
      border = palette.bright.white;
      urgency-normal.bg = palette.bright.black;
      urgency-normal.fg = palette.bright.white;
    };
  };
in
rec {
  border = c.${colorscheme}.border or palette.normal.white;

  urgency-normal.bg = c.${colorscheme}.urgency-normal.bg or palette.normal.black;
  urgency-normal.fg = c.${colorscheme}.urgency-normal.fg or palette.normal.white;

  urgency-low = urgency-normal;
  urgency-critical = urgency-normal;
}
