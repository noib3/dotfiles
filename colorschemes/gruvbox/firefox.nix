let
  colors = import ./palette.nix;
in
{
  tabs = {
    unfocused = {
      bg = colors.normal.black;
      fg = colors.bright.white;
    };

    focused = {
      bg = colors.bright.white;
      fg = colors.normal.black;
    };
  };

  urlbar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    url.fg = colors.bright.blue;
    separator = colors.bright.white;

    selected = {
      bg = colors.bright.blue;
      fg = colors.bright.black;
    };
  };

  sidebar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
  };

  about-blank.bg = colors.normal.black;
}
