{ family }:

let
  f = {
    "Iosevka Nerd Font".size = 14;
    "Mononoki Nerd Font".size = 14;
  };
in
{
  size = f.${family}.size or 13;
}
