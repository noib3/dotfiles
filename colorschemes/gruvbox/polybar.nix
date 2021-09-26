let
  colors = import ./palette.nix;
  hexlib = import ../hexlib.nix;
in
rec {
  bar = {
    fg = colors.bright.white;
    bg = "#00000000";
  };

  power.icon = bar.fg;

  workspaces = rec {
    focused.bg = colors.normal.black;
    focused.fg = occupied.fg;
    occupied.fg = bar.fg;
    empty.fg = hexlib.scale 70 colors.bright.white;
  };

  bluetooth = {
    icon.on = bar.fg;
    icon.off = colors.bright.white;
    icon.connected = colors.normal.blue;
  };

  wifi = {
    icon.on = colors.normal.green;
    icon.off = colors.bright.white;
  };

  ethernet.icon = colors.bright.yellow;

  battery = {
    icon.charging = colors.normal.cyan;
    icon.dying = colors.normal.red;
    icon.low = colors.normal.yellow;
    icon.ok = colors.normal.green;
  };

  datetime.icon = colors.normal.yellow;
  notification-center.icon = bar.fg;
}
