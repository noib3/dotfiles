let
  colors = import ./palette.nix;
  onehundredtwenty-percent-bright-black = "#4b5263";
  onehundredtwentyfive-percent-black = "#32363e";
  firefox-private-urlbar = "#25003e";
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
    indicator.error = colors.bright.red;
    indicator.start = colors.normal.blue;
    indicator.stop = colors.normal.green;
  };

  hints = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    match.fg = colors.normal.yellow;
  };

  completion = rec {
    fg = colors.normal.white;
    odd.bg = onehundredtwenty-percent-bright-black;
    even.bg = colors.bright.black;
    header.bg = colors.normal.black;
    header.fg = colors.normal.blue;
    urls.fg = colors.normal.blue;
    match.fg = colors.bright.red;
    selected = {
      fg = colors.normal.black;
      bg = colors.normal.blue;
      match.fg = match.fg;
    };
  };

  statusbar = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    private.bg = firefox-private-urlbar;
    private.fg = colors.normal.white;
  };

  messages = {
    error = {
      bg = colors.bright.red;
      fg = colors.normal.white;
    };
  };

  dmenu = rec {
    normal.fg = colors.normal.white;
    normal.bg = colors.normal.black;
    prompt.fg = colors.normal.blue;
    prompt.bg = normal.bg;
    selected.fg = colors.normal.white;
    selected.bg = onehundredtwentyfive-percent-black;
    highlight.fg = colors.normal.yellow;
  };
}
