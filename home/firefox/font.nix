{ family
, machine
}:

let
  overrides = {
    "Iosevka Nerd Font" = {
    };
    "Mononoki Nerd Font" = {
    };
  };

  default_size = {
    "skunk" = 19;
  };
in
{
  inherit family;
  size = overrides.${family}.${machine}.size or default_size.${machine};
}
