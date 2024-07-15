{ family }:

let
  f = {
    "Iosevka Nerd Font".size = 16;
    "Mononoki Nerd Font".size = 16;
  };
in
{
  size = f.${family}.size or 15;
}
