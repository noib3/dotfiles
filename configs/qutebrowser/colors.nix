{
  config,
  colorscheme,
  palette,
}:

let
  inherit (config.lib.mine) hex;
  c = {
    "afterglow" = {
      tabs = {
        unfocused.bg = hex.scale 1.5 palette.normal.black;
      };
      hints = {
        fg = palette.normal.white;
        match.fg = palette.normal.yellow;
      };
      completion = {
        fg = hex.scale 0.95 palette.normal.white;
        odd.bg = hex.scale 1.5 palette.normal.black;
        even.bg = palette.normal.black;
        header.fg = palette.normal.magenta;
        match.fg = palette.normal.magenta;
        selected.bg = palette.bright.black;
        selected.fg = palette.normal.white;
      };
      statusbar = {
        bg = palette.normal.black;
        fg = hex.scale 0.95 palette.normal.white;
      };
      dmenu = {
        normal.bg = hex.scale 1.5 palette.normal.black;
        prompt.fg = palette.normal.magenta;
        highlight.fg = palette.normal.magenta;
      };
    };
    "gruvbox" = {
      tabs = {
        unfocused.fg = palette.bright.white;
        focused.bg = hex.scale 1.3 palette.bright.white;
      };
      statusbar.fg = hex.scale 1.3 palette.bright.white;
    };
    "tokyonight" = {
      tabs.unfocused.fg = palette.bright.white;
      tabs.focused.bg = palette.bright.white;
      statusbar.private.bg = "#3b4261";
      statusbar.private.fg = "#bb9af7";
    };
  };
in
{
  tabs = {
    unfocused = {
      bg = c.${colorscheme}.tabs.unfocused.bg or palette.normal.black;
      fg = c.${colorscheme}.tabs.unfocused.fg or palette.normal.white;
    };
    focused = {
      bg = c.${colorscheme}.tabs.focused.bg or palette.normal.white;
      fg = palette.normal.black;
    };
    indicator.error = c.${colorscheme}.tabs.indicator.error or palette.normal.red;
    indicator.start = palette.normal.blue;
    indicator.stop = palette.normal.green;
  };

  hints = {
    bg = palette.bright.black;
    fg = c.${colorscheme}.hints.fg or palette.bright.white;
    match.fg = c.${colorscheme}.hints.match.fg or palette.normal.magenta;
  };

  completion = rec {
    fg = c.${colorscheme}.completion.fg or palette.normal.white;
    odd.bg = c.${colorscheme}.completion.odd.bg or (hex.scale 1.2 palette.bright.black);
    even.bg = c.${colorscheme}.completion.odd.bg or palette.bright.black;
    header.bg = palette.normal.black;
    header.fg = c.${colorscheme}.completion.header.fg or palette.normal.blue;
    urls.fg = palette.normal.blue;
    match.fg = c.${colorscheme}.completion.match.fg or palette.bright.red;
    selected = {
      bg = c.${colorscheme}.completion.selected.bg or palette.normal.blue;
      fg = c.${colorscheme}.completion.selected.fg or palette.normal.black;
      match.fg = match.fg;
    };
  };

  statusbar = rec {
    bg = c.${colorscheme}.statusbar.bg or palette.primary.background;
    fg = c.${colorscheme}.statusbar.fg or palette.primary.foreground;

    insert = {
      bg = bg;
      fg = c.${colorscheme}.statusbar.insert.fg or palette.normal.white;
    };

    passthrough = {
      bg = bg;
      fg = c.${colorscheme}.statusbar.fg or palette.normal.yellow;
    };

    private = {
      bg = c.${colorscheme}.statusbar.private.bg or palette.normal.magenta;
      fg = c.${colorscheme}.statusbar.private.fg or fg;
    };

    url = rec {
      fg = palette.normal.green;
      hover.fg = fg;
      success.http.fg = fg;
      success.https.fg = fg;
      warn.fg = palette.normal.yellow;
      error.fg = palette.normal.red;
    };
  };

  messages = {
    error = {
      bg = c.${colorscheme}.messages.error.bg or palette.normal.red;
      fg = palette.normal.white;
    };
  };

  dmenu = rec {
    normal.fg = palette.normal.white;
    normal.bg = c.${colorscheme}.dmenu.normal.bg or palette.normal.black;
    prompt.fg = c.${colorscheme}.dmenu.prompt.fg or palette.normal.blue;
    prompt.bg = normal.bg;
    selected.fg = palette.normal.white;
    selected.bg = hex.scale 1.25 palette.normal.black;
    highlight.fg = c.${colorscheme}.dmenu.highlight.fg or palette.normal.yellow;
  };
}
