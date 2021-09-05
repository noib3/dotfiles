let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
{
  tabs = {
    unfocused = {
      bg = colors.normal.black;
      fg = colors.bright.white;
    };

    focused = {
      bg = hexlib.scale 130 colors.bright.white;
      fg = colors.normal.black;
    };
  };

  urlbar = {
    bg = colors.bright.black;
    fg = hexlib.scale 130 colors.bright.white;
    urls.fg = colors.normal.blue;
    separator = colors.bright.white;
    selected = {
      bg = colors.normal.blue;
      fg = colors.normal.black;
    };
  };

  sidebar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
  };

  about-blank.bg = colors.normal.black;
}
