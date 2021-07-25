{ machine }:

let
  family = "JetBrainsMono Nerd Font";
in
rec {
  normal = {
    inherit family;
    style = "Regular";
  };

  bold = {
    inherit family;
    style = "Extra Bold";
  };

  italic = {
    inherit family;
    style = "Italic";
  };

  bold_italic = {
    inherit family;
    style = "Extra Bold";
  };
} // (
  if machine == "blade" then
    {
      size = 12;
    }
  else if machine == "mbair" then
    {
      size = 19;
      offset.y = 1;
      glyph_offset.y = 1;
    }
  else { }
)
