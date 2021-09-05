let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
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
    indicator.error = colors.normal.red;
    indicator.start = colors.normal.blue;
    indicator.stop = colors.normal.green;
  };

  hints = {
    bg = colors.bright.black;
    fg = colors.bright.white;
    match.fg = colors.normal.magenta;
  };

  completion = rec {
    fg = colors.normal.white;
    odd.bg = hexlib.scale 120 colors.bright.black;
    even.bg = colors.bright.black;
    header.bg = colors.normal.black;
    header.fg = colors.normal.blue;
    urls.fg = colors.normal.blue;
    match.fg = colors.bright.red;
    selected = {
      bg = colors.normal.blue;
      fg = colors.normal.black;
      match.fg = match.fg;
    };
  };

  statusbar = rec{
    bg = colors.bright.black;
    fg = colors.normal.white;
    private.bg = hexlib.scale 65 colors.normal.magenta;
    private.fg = fg;
  };

  messages = {
    error = {
      bg = colors.normal.red;
      fg = colors.normal.white;
    };
  };

  dmenu = rec {
    normal.fg = colors.normal.white;
    normal.bg = colors.normal.black;
    prompt.fg = colors.normal.blue;
    prompt.bg = normal.bg;
    selected.fg = colors.normal.white;
    selected.bg = hexlib.scale 125 colors.normal.black;
    highlight.fg = colors.normal.yellow;
  };
}
