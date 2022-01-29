{ colorscheme, palette }:

let
  c = {
    "afterglow" = {
      boot-entry.selected.bg = palette.normal.magenta;
    };
  };
in
rec {
  boot-entry = {
    fg = palette.normal.white;
    selected.bg =
      c.${colorscheme}.boot-entry.selected.bg
        or palette.normal.blue;
    selected.fg = palette.normal.black;
  };
  countdown-message.fg = boot-entry.selected.bg;
  navigation-keys-message.fg = palette.bright.white;
}
