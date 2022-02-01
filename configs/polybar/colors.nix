{ colorscheme, palette, hexlib }:

let
  c = {
    "afterglow" = {
      bag.fg = hexlib.scale 0.95 palette.normal.white;
      workspaces.empty.fg = palette.bright.white;
    };
  };
in
rec {
  bar = {
    fg = c.${colorscheme}.bar.fg or palette.bright.white;
    bg = "#00000000";
  };

  power.icon = bar.fg;

  workspaces = rec {
    focused.bg = palette.normal.black;
    focused.fg = occupied.fg;
    occupied.fg = bar.fg;
    empty.fg =
      c.${colorscheme}.workspaces.empty.fg
        or (hexlib.scale 0.7 palette.bright.white);
  };

  bluetooth = {
    icon.on = bar.fg;
    icon.off = palette.bright.white;
    icon.connected = palette.normal.blue;
  };

  wifi = {
    icon.on = palette.normal.green;
    icon.off = palette.bright.white;
  };

  ethernet.icon = palette.bright.yellow;

  battery = {
    icon.charging = palette.normal.cyan;
    icon.dying = palette.normal.red;
    icon.low = palette.normal.yellow;
    icon.ok = palette.normal.green;
  };

  datetime.icon = palette.normal.yellow;
  notification-center.icon = bar.fg;
}
