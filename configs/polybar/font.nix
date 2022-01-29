{ family }:

let
  f = {
    "Iosevka Nerd Font" = {
      icons.default = {
        size = 21;
        padding-top = 5;
      };
      icons.videos = {
        size = 23;
        padding-top = 5;
      };
      icons.wifi = {
        size = 28;
        padding-top = 6;
      };
      icons.battery = {
        size = 14;
        padding-top = 3;
      };
      icons.calendar = {
        size = 18;
        padding-top = 4;
      };
      icons.menu.size = 20;
    };
    "Mononoki Nerd Font" = {
      icons.default = {
        size = 21;
        padding-top = 5;
      };
      icons.videos = {
        size = 23;
        padding-top = 5;
      };
      icons.wifi = {
        size = 24;
        padding-top = 4;
      };
      icons.battery = {
        size = 14;
        padding-top = 3;
      };
      icons.calendar = {
        size = 18;
        padding-top = 4;
      };
      icons.menu.size = 20;
    };
  };
in
{
  text = {
    inherit family;
    style = "Regular";
    size = 13;
    padding-top = 3;
  };

  icons = rec {
    default = {
      family = family + " Mono";
      style = "Regular";
      size = f.${family}.icons.default.padding-top or 17;
      padding-top = f.${family}.icons.default.padding-top or 4;
    };
    videos = default // {
      size = f.${family}.icons.videos.padding-top or 18;
      padding-top =
        f.${family}.icons.videos.padding-top
          or default.padding-top;
    };
    bluetooth = default // {
      size = 16;
      padding-top = 3;
    };
    wifi = default // {
      size = f.${family}.icons.wifi.size or 21;
      padding-top =
        f.${family}.icons.wifi.padding-top
          or default.padding-top;
    };
    battery = default // {
      size = f.${family}.icons.battery.size or 12;
      padding-top = f.${family}.icons.battery.padding-top or 2;
    };
    calendar = default // {
      size = f.${family}.icons.calendar.size or 16;
      padding-top = f.${family}.icons.calendar.padding-top or 3;
    };
    menu = default // {
      size = f.${family}.icons.menu.size or 19;
    };
  };
}
