{ config, isDarwin }:

let
  font = config.fonts.monospace;
in
{
  font-family = font.name;
  font-size = font.size config "ghostty";
  font-style = font.normal;
  font-style-bold = font.bold;
  font-style-italic = font.italic;
  font-style-bold-italic = font.bold_italic;
  font-thicken = isDarwin;
}
