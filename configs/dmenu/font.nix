{ family }:

let
  f = {
    "Iosevka Nerd Font".size = 13;
    "Mononoki Nerd Font".size = 13;
  };
in
{
  inherit family;
  size = f.${family}.size or 12;
  lineheight = f.${family}.size or 25;
}
