{
  config,
}:

let
  inherit (config.lib.mine) hex;
  inherit (config.modules.colorscheme) name palette;
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
      bg = c.${name}.tabs.unfocused.bg or palette.normal.black;
      fg = c.${name}.tabs.unfocused.fg or palette.normal.white;
    };
    focused = {
      bg = c.${name}.tabs.focused.bg or palette.normal.white;
      fg = palette.normal.black;
    };
    indicator.error = c.${name}.tabs.indicator.error or palette.normal.red;
    indicator.start = palette.normal.blue;
    indicator.stop = palette.normal.green;
  };

  hints = {
    bg = palette.bright.black;
    fg = c.${name}.hints.fg or palette.bright.white;
    match.fg = c.${name}.hints.match.fg or palette.normal.magenta;
  };

  completion = rec {
    fg = c.${name}.completion.fg or palette.normal.white;
    odd.bg = c.${name}.completion.odd.bg or (hex.scale 1.2 palette.bright.black);
    even.bg = c.${name}.completion.odd.bg or palette.bright.black;
    header.bg = palette.normal.black;
    header.fg = c.${name}.completion.header.fg or palette.normal.blue;
    urls.fg = palette.normal.blue;
    match.fg = c.${name}.completion.match.fg or palette.bright.red;
    selected = {
      bg = c.${name}.completion.selected.bg or palette.normal.blue;
      fg = c.${name}.completion.selected.fg or palette.normal.black;
      match.fg = match.fg;
    };
  };

  statusbar = rec {
    bg = c.${name}.statusbar.bg or palette.primary.background;
    fg = c.${name}.statusbar.fg or palette.primary.foreground;

    insert = {
      bg = bg;
      fg = c.${name}.statusbar.insert.fg or palette.normal.white;
    };

    passthrough = {
      bg = bg;
      fg = c.${name}.statusbar.fg or palette.normal.yellow;
    };

    private = {
      bg = c.${name}.statusbar.private.bg or palette.normal.magenta;
      fg = c.${name}.statusbar.private.fg or fg;
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
      bg = c.${name}.messages.error.bg or palette.normal.red;
      fg = palette.normal.white;
    };
  };

  dmenu = rec {
    normal.fg = palette.normal.white;
    normal.bg = c.${name}.dmenu.normal.bg or palette.normal.black;
    prompt.fg = c.${name}.dmenu.prompt.fg or palette.normal.blue;
    prompt.bg = normal.bg;
    selected.fg = palette.normal.white;
    selected.bg = hex.scale 1.25 palette.normal.black;
    highlight.fg = c.${name}.dmenu.highlight.fg or palette.normal.yellow;
  };
}
