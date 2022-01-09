{ colorscheme, palette }:

let
  hexlib = import ../../colorschemes/hexlib.nix;
  c = {
    "afterglow" = {
      current-line.bg = hexlib.scale 1.5 palette.normal.black;
      grayed-out-directories = hexlib.scale 0.85 palette.bright.white;
    };
    "gruvbox" = {
      current-line.bg = hexlib.scale 0.9 palette.bright.black;
      grayed-out-directories = hexlib.scale 1.3 palette.bright.black;
    };
    "nord" = {
      current-line.bg = hexlib.scale 0.9 palette.bright.black;
      grayed-out-directories = hexlib.scale 1.3 palette.bright.black;
    };
    "onedark".current-line.bg = hexlib.scale 0.8 palette.bright.black;
    "tokyonight" = {
      current-line.bg = hexlib.scale 0.75 palette.bright.black;
      grayed-out-directories = "#565f89";
    };
  };
in
{
  current-line.bg = c.${colorscheme}.current-line.bg or palette.bright.black;
  border = palette.bright.black;
  directories = palette.normal.blue;
  grayed-out-directories = c.${colorscheme}.grayed-out-directories or palette.bright.white;
}
