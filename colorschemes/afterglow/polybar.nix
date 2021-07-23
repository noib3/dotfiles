let
  colors = import ./palette.nix;
  hexlib = import ../../colorschemes/hexlib.nix;
in
rec {
  bar = {
    fg = hexlib.scale 95 colors.normal.white;
    bg = "#00000000";
  };

  power.icon = bar.fg;

  workspaces = {
    focused.bg = hexlib.scale 120 colors.normal.black;
    occupied.fg = bar.fg;
    empty.fg = colors.bright.white;
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
    icon.charging = colors.normal.magenta;
    icon.dying = colors.normal.red;
    icon.low = colors.normal.yellow;
    icon.ok = colors.normal.green;
  };

  datetime.icon = colors.bright.yellow;
  notification-center.icon = bar.fg;
}
