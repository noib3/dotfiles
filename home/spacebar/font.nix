{ family }:

let
  f = {
    "Iosevka Nerd Font" = { size = 19; };
    "Mononoki Nerd Font" = { size = 19; };
  };
in
{
  inherit family;
  style = "Regular";
  size = f.${family}.size or "18";
}
