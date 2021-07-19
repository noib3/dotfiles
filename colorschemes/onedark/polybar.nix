let
  colors = import ./palette.nix;
  ninety-percent-white = "#9aa0ac";
in
rec {
  bar.fg = ninety-percent-white;
  bar.bg = "#00000000";

  power.icon = bar.fg;

  workspaces = {
    focused.bg = colors.normal.black;
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
    icon.charging = colors.normal.cyan;
    icon.dying = colors.normal.red;
    icon.low = colors.normal.yellow;
    icon.ok = colors.normal.green;
  };

  datetime.icon = colors.normal.yellow;
  notification-center.icon = bar.fg;
}
