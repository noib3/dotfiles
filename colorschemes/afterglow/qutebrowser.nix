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
    indicator.error = colors.normal.red;
    indicator.start = colors.normal.blue;
    indicator.stop = colors.normal.green;
  };

  hints = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    match.fg = colors.normal.yellow;
  };

  completion = rec {
    fg = hexlib.scale 95 colors.normal.white;
    odd.bg = hexlib.scale 150 colors.normal.black;
    even.bg = colors.normal.black;
    header.bg = colors.normal.black;
    header.fg = colors.normal.magenta;
    urls.fg = colors.normal.blue;
    match.fg = colors.normal.magenta;
    selected = {
      bg = colors.bright.black;
      fg = colors.normal.white;
      match.fg = match.fg;
    };
  };

  statusbar = rec {
    bg = colors.normal.black;
    fg = hexlib.scale 95 colors.normal.white;
    private.bg = colors.normal.magenta;
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
    normal.bg = hexlib.scale 150 colors.normal.black;
    prompt.fg = colors.normal.magenta;
    prompt.bg = normal.bg;
    selected.fg = colors.normal.white;
    selected.bg = hexlib.scale 125 colors.normal.black;
    highlight.fg = colors.normal.magenta;
  };
}
