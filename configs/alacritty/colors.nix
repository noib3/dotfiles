{ config }:

let
  inherit (config.modules.colorscheme) palette;
in
{
  inherit (palette) normal bright;

  primary = {
    foreground = palette.primary.foreground or palette.normal.white;
    background = palette.primary.background or palette.normal.black;
  };

  cursor = {
    text = palette.cursor.text or palette.bright.black;
    cursor = palette.cursor.cursor or palette.normal.white;
  };

  selection = {
    text = palette.selection.text or palette.normal.white;
    background = palette.selection.background or palette.bright.black;
  };
}
