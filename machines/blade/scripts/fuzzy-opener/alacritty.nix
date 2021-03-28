{ font, colors }:

{
  font = {
    normal = font.normal;
    bold = font.bold;
    italic = font.italic;
    bold_italic = font.bold_italic;
    size = 18;
  };

  colors = colors;

  cursor.style = "Beam";

  window = {
    padding.x = 200;
    padding.y = 200;
  };

  key_bindings = [
    {
      key = "Left";
      mods = "Super";
      chars = "\\x01"; # C-a
    }
    {
      key = "Right";
      mods = "Super";
      chars = "\\x05"; # C-e
    }
    {
      key = "Back";
      mods = "Super";
      chars = "\\x15"; # C-u
    }
  ];
}
