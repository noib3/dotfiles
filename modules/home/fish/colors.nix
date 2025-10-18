{ config }:

let
  inherit (config.modules.colorscheme) palette;
in
{
  autosuggestion = palette.bright.white;
  comment = palette.bright.white;
  param = palette.normal.cyan;
  operator = palette.normal.cyan;
  end = palette.normal.cyan;
  selection_bg = palette.bright.black;
}
