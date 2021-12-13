{ machine }:

let
  family = "Iosevka Nerd Font";
in
rec {
  normal = {
    inherit family;
    style = "Regular";
  };

  bold = {
    inherit family;
    style = "Bold";
  };

  italic = {
    inherit family;
    style = "Italic";
  };

  bold_italic = {
    inherit family;
    style = "Bold";
  };

  size =
    if machine == "blade" then
      10
    else if machine == "mbair" then
      19
    else
      10;
}
