{ machine }:

{
  normal = {
    family = "FiraCode Nerd Font";
    style = "Regular";
  };

  bold = {
    family = "FiraCode Nerd Font";
    style = "Bold";
  };

  italic = {
    family = "FiraCode Nerd Font";
    style = "Italic";
  };

  bold_italic = {
    family = "FiraCode Nerd Font";
    style = "Bold";
  };
} // (
  if machine == "blade" then
    {
      size = 9;
    }
  else if machine == "mbair" then
    {
      size = 19;
    }
  else { }
)
