{ config }:

let
  inherit (config.modules.colorscheme) palette;
in
{
  foreground = palette.primary.foreground or palette.normal.white;
  background = palette.primary.background or palette.normal.black;

  cursor-text = palette.cursor.text or palette.bright.black;
  cursor-color = palette.cursor.cursor or palette.normal.white;

  selection-foreground = palette.selection.text or palette.normal.white;
  selection-background = palette.selection.background or palette.bright.black;

  palette = [
    # Normal colors.
    "0=${palette.normal.black}"
    "1=${palette.normal.red}"
    "2=${palette.normal.green}"
    "3=${palette.normal.yellow}"
    "4=${palette.normal.blue}"
    "5=${palette.normal.magenta}"
    "6=${palette.normal.cyan}"
    "7=${palette.normal.white}"
    # Bright colors.
    "8=${palette.bright.black}"
    "9=${palette.bright.red}"
    "10=${palette.bright.green}"
    "11=${palette.bright.yellow}"
    "12=${palette.bright.blue}"
    "13=${palette.bright.magenta}"
    "14=${palette.bright.cyan}"
    "15=${palette.bright.white}"
  ];
}
