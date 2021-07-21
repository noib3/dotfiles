let
  colors = import ./palette.nix;
  ninetyseven-percent-white = "#bababa";
  onehundredtwenty-percent-black = "#282828";
in
rec {
  bar.fg = ninetyseven-percent-white;
  bar.bg = "#00000000";

  power.icon = bar.fg;

  workspaces = {
    focused.bg = onehundredtwenty-percent-black;
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
