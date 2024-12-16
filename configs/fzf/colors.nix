{
  config,
}:

let
  inherit (config.lib.mine) hex;
  inherit (config.modules.colorscheme) name palette;
  c = {
    "afterglow" = {
      current-line.bg = hex.scale 1.5 palette.normal.black;
      grayed-out-directories = hex.scale 0.85 palette.bright.white;
    };
    "gruvbox" = {
      current-line.bg = hex.scale 0.9 palette.bright.black;
      grayed-out-directories = hex.scale 1.3 palette.bright.black;
    };
    "tokyonight" = {
      current-line.bg = hex.scale 0.75 palette.bright.black;
      grayed-out-directories = "#565f89";
    };
    "vscode" = {
      current-line.bg = hex.scale 0.7 palette.bright.black;
      grayed-out-directories = palette.bright.black;
    };
  };
in
{
  current-line.bg = c.${name}.current-line.bg or palette.bright.black;
  border = palette.bright.black;
  directories = palette.normal.blue;
  grayed-out-directories = c.${name}.grayed-out-directories or palette.bright.white;
}
