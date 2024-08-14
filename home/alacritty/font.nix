{ config }:

let
  family = config.fontFamily.name;
  font = config.fontFamily.alacritty;
in
{
  size = font.size or 16;

  normal = {
    inherit family;
    style = font.regular.style or "Regular";
  };

  bold = {
    inherit family;
    style = font.bold.style or "Bold";
  };

  italic = {
    inherit family;
    style = font.italic.style or "Italic";
  };

  bold_italic = {
    inherit family;
    style = font.bold_italic.style or "Bold Italic";
  };
}
