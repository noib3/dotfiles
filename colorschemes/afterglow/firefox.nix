let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix { };
in
{
  tabs = {
    unfocused = {
      bg = hexlib.scale 150 colors.normal.black;
      fg = colors.normal.white;
    };

    focused = {
      bg = colors.normal.white;
      fg = colors.normal.black;
    };
  };

  urlbar = {
    bg = colors.bright.black;
    fg = hexlib.scale 95 colors.normal.white;
    urls.fg = colors.normal.blue;
    separator = colors.bright.white;
    selected = {
      bg = colors.bright.black;
      fg = colors.normal.white;
    };
  };

  sidebar = {
    bg = colors.normal.white;
    fg = colors.bright.black;
  };

  about-blank.bg = colors.normal.black;
}
