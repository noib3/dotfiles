{ colorscheme
, palette
, hexlib
}:

let
  c = {
    "afterglow" = {
      tabs.unfocused = {
        bg = hexlib.scale 150 palette.normal.black;
        fg = palette.normal.white;
      };
      tabs.focused = {
        bg = palette.normal.white;
      };
      urlbar = {
        fg = hexlib.scale 95 palette.normal.white;
        selected.bg = palette.bright.black;
        selected.fg = palette.normal.white;
      };
      sidebar = {
        bg = palette.normal.white;
        fg = palette.bright.black;
      };
    };
  };
in
{
  tabs = {
    unfocused = {
      bg = c.${colorscheme}.tabs.unfocused.bg or palette.normal.black;
      fg = c.${colorscheme}.tabs.unfocused.fg or palette.bright.white;
    };

    focused = {
      bg =
        c.${colorscheme}.tabs.focused.fg
          or (hexlib.scale 130 palette.bright.white);
      fg = palette.normal.black;
    };
  };

  urlbar = {
    bg = palette.bright.black;
    fg = c.${colorscheme}.urlbar.fg or (hexlib.scale 130 palette.bright.white);
    urls.fg = palette.normal.blue;
    separator = palette.bright.white;
    selected = {
      bg = c.${colorscheme}.urlbar.selected.bg or palette.normal.blue;
      fg = c.${colorscheme}.urlbar.selected.fg or palette.normal.black;
    };
  };

  sidebar = {
    bg = c.${colorscheme}.sidebar.bg or palette.bright.black;
    fg = c.${colorscheme}.sidebar.fg or palette.normal.white;
  };

  about-blank.bg = palette.normal.black;
}
