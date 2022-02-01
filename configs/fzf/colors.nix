{ hexlib, colorscheme, palette }:

let
  c = {
    "afterglow" = {
      current-line.bg = hexlib.scale 1.5 palette.normal.black;
      grayed-out-directories = hexlib.scale 0.85 palette.bright.white;
    };
    "gruvbox" = {
      current-line.bg = hexlib.scale 0.9 palette.bright.black;
      grayed-out-directories = hexlib.scale 1.3 palette.bright.black;
    };
    "tokyonight" = {
      current-line.bg = hexlib.scale 0.75 palette.bright.black;
      grayed-out-directories = "#565f89";
    };
    "vscode" = {
      current-line.bg = hexlib.scale 0.7 palette.bright.black;
      grayed-out-directories = palette.bright.black;
    };
  };
in
{
  current-line.bg = c.${colorscheme}.current-line.bg or palette.bright.black;
  border = palette.bright.black;
  directories = palette.normal.blue;
  grayed-out-directories = c.${colorscheme}.grayed-out-directories or palette.bright.white;
}
