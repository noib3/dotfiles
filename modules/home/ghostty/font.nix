{
  config,
  lib,
  isDarwin,
}:

let
  font = config.modules.fonts.current.monospace;
in
{
  font-family = font.name;
  font-size = font.sizes "ghostty";
  font-style = font.styles.normal;
  font-style-bold = font.styles.bold;
  font-style-italic = font.styles.italic;
  font-style-bold-italic = font.styles.boldItalic;
}
// lib.optionalAttrs isDarwin {
  font-thicken = true;
}
