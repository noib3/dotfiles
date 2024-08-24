{ config }:

let
  font = config.fonts.monospace;
  family = font.name;
in
{
  size = font.size config "alacritty";

  normal = {
    inherit family;
    style = font.normal;
  };

  bold = {
    inherit family;
    style = font.bold;
  };

  italic = {
    inherit family;
    style = font.italic;
  };

  bold_italic = {
    inherit family;
    style = font.bold_italic;
  };
}
