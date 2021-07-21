let
  colors = import ./palette.nix;
  onehundredtwentyfive-percent-black = "#212121";
  ciao = "#282828";
  ninetysix-percent-white = "#b9b9b9";
in
{
  tabs = {
    unfocused = {
      bg = ciao;
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
    fg = ninetysix-percent-white;
    odd.bg = ciao;
    even.bg = colors.normal.black;
    header.bg = colors.normal.black;
    header.fg = colors.normal.magenta;
    urls.fg = colors.normal.blue;
    match.fg = colors.normal.magenta;
    selected = {
      fg = colors.normal.white;
      bg = colors.bright.black;
      match.fg = match.fg;
    };
  };

  statusbar = {
    bg = colors.normal.black;
    fg = ninetysix-percent-white;
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
    normal.bg = ciao;
    prompt.fg = colors.normal.magenta;
    prompt.bg = normal.bg;
    selected.fg = colors.normal.white;
    selected.bg = onehundredtwentyfive-percent-black;
    highlight.fg = colors.normal.magenta;
  };
}
