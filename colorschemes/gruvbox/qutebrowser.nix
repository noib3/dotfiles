let
  colors = import ./palette.nix;
  hints = "#b57614";
  onehundredtwenty-percent-bright-black = "#484341";
  onehundredtwentyfive-percent-black = "#323232";
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
    indicator.error = colors.normal.red;
    indicator.start = colors.normal.blue;
    indicator.stop = colors.normal.green;
  };

  hints = {
    bg = colors.bright.black;
    fg = colors.normal.white;
    match.fg = hints;
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
    private.bg = colors.normal.magenta;
    private.fg = colors.normal.white;
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
    selected.bg = onehundredtwentyfive-percent-black;
    highlight.fg = colors.normal.yellow;
  };
}
