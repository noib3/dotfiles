{ machine }:

let
  family = "RobotoMono Nerd Font";
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
    style = "Bold Italic";
  };
} // (
  if machine == "blade" then
    {
      size = 9;
      offset.y = 1;
    }
  else if machine == "mbair" then
    {
      size = 19;
      offset.y = 1;
    }
  else { }
)
