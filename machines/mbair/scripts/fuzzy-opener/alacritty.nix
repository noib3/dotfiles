{ font, colors }:

{
  font = {
    normal = font.normal;
    bold = font.bold;
    italic = font.italic;
    bold_italic = font.bold_italic;
    size = 35;
  };

  colors = colors;

  cursor.style = "Beam";

  window = {
    decorations = "buttonless";
    dimensions.columns = 50;
    dimensions.lines = 10;
    padding.x = 10;
    padding.y = 5;
  };

  key_bindings = [
    {
      key = "LBracket";
      mods = "Alt|Shift";
      chars = "\\x7B"; # {
    }
    {
      key = "RBracket";
      mods = "Alt|Shift";
      chars = "\\x7D"; # }
    }
    {
      key = "LBracket";
      mods = "Alt";
      chars = "\\x5B"; # [
    }
    {
      key = "RBracket";
      mods = "Alt";
      chars = "\\x5D"; # ]
    }
    {
      key = 23;
      mods = "Alt";
      chars = "\\x7E"; # ~
    }
    {
      key = 41;
      mods = "Alt";
      chars = "\\x40"; # @
    }
    {
      key = 39;
      mods = "Alt";
      chars = "\\x23"; # #
    }
    {
      key = 10;
      mods = "Alt";
      chars = "\\x60"; # `
    }
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
