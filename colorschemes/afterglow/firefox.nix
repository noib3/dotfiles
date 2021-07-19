let
  colors = import ./palette.nix;
in
{
  tabs = {
    unfocused = {
      bg = colors.normal.black;
      fg = colors.normal.white;
    };

    focused = {
      bg = colors.normal.white;
      fg = colors.normal.black;
    };
  };

  urlbar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    url.fg = colors.normal.blue;
    separator = colors.bright.white;

    selected = {
      bg = colors.normal.blue;
      fg = colors.normal.black;
    };
  };

  sidebar = {
    bg = colors.normal.white;
    fg = colors.bright.black;
  };

  about-blank.bg = colors.normal.black;
}
