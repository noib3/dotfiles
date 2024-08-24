{ family }:

let
  f = {
    "Iosevka Nerd Font" = {
      hints.size = 13;
      commandline.size = 15;
    };
    "Mononoki Nerd Font" = {
      hints.size = 13;
      commandline.size = 15;
    };
  };
in
{
  inherit family;
  hints.size = c.${family}.hints.size or 12;
  commandline.size = c.${family}.hints.size or 14;
}
