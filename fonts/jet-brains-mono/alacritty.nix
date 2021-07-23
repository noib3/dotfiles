{ machine }:

{
  normal = {
    family = "JetBrainsMono Nerd Font";
    style = "Regular";
  };

  bold = {
    family = "JetBrainsMono Nerd Font";
    style = "Extra Bold";
  };

  italic = {
    family = "JetBrainsMono Nerd Font";
    style = "Italic";
  };

  bold_italic = {
    family = "JetBrainsMono Nerd Font";
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
