{ colorscheme
, palette
, hexlib
}:

let
  c = {
    "afterglow" = {
      border.focused = hexlib.scale 0.95 palette.normal.white;
      border.unfocused = hexlib.scale 2.2 palette.normal.black;
    };

    "gruvbox" = {
      border.focused = hexlib.scale 1.3 palette.bright.white;
    };

    "tokyonight" = {
      border.focused = palette.primary.foreground;
    };
  };
in
{
  border = {
    focused = c."${colorscheme}".border.focused or palette.normal.white;
    unfocused = c."${colorscheme}".border.unfocused or palette.bright.black;
  };
}
