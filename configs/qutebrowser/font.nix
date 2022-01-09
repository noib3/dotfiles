{ family }:

let
  f = {
    "Inconsolata Nerd Font".size = 16;
    "Iosevka Nerd Font" = {
      size = 15;
      dmenu.size = 13;
    };
    "Mononoki Nerd Font" = {
      size = 15;
      dmenu.size = 13;
    };
  };
in
rec {
  size = f.${family}.size or 14;

  dmenu = {
    size = f.${family}.dmenu.size or 12;
    lineheight = 24;
  };
}
