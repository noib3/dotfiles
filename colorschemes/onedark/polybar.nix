rec {
  bar.fg = "#9aa0ac";
  bar.bg = "#0014161a";

  power.icon = bar.fg;

  workspaces = {
    focused.bg = "#282c34";
    occupied.fg = bar.fg;
    empty.fg = "#5c6073";
  };

  bluetooth = {
    icon.on = bar.fg;
    icon.off = "#5c6073";
    icon.connected = "#61afef";
  };

  wifi = {
    icon.on = "#98c379";
    icon.off = "#5c6073";
  };

  ethernet.icon = "#d19a66";

  battery = {
    icon.charging = "#56b6c2";
    icon.dying = "#e06c75";
    icon.low = "#e5c07b";
    icon.ok = "#98c379";
  };

  datetime.icon = "#e5c07b";
  notification-center.icon = bar.fg;
}
