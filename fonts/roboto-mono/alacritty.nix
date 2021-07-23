{ machine }:

{
  normal = {
    family = "RobotoMono Nerd Font";
    style = "Regular";
  };

  bold = {
    family = "RobotoMono Nerd Font";
    style = "Bold";
  };

  italic = {
    family = "RobotoMono Nerd Font";
    style = "Italic";
  };

  bold_italic = {
    family = "RobotoMono Nerd Font";
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
