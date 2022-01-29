{ family, machine }:

let
  f = {
    "Iosevka Nerd Font" = {
      "blade".size = 23;
      "mbair".size = 20;
    };
    "Mononoki Nerd Font" = {
      "blade".size = 23;
      "mbair".size = 20;
    };
  };

  default_size = {
    "blade" = 22;
    "mbair" = 19;
  };
in
{
  inherit family;
  size = f.${family}.${machine}.size or default_size.${machine};
}
