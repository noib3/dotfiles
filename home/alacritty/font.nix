{ family
, machine
}:

let
  overrides = {
    "FiraCode Nerd Font" = {
      bold_italic.style = "Bold";
    };

    "Inconsolata Nerd Font" = {
      "skunk".size = 17;
    };

    "JetBrainsMono Nerd Font" = {
      bold.style = "Extra Bold";
      bold_italic.style = "Extra Bold";
    };

    "Mononoki Nerd Font" = {
      bold_italic.style = "Bold";
    };
  };

  default_size = {
    "skunk" = 10;
  };
in
{
  normal = {
    inherit family;
    style = "Regular";
  };

  bold = {
    inherit family;
    style = overrides.${family}.bold.style or "Bold";
  };

  italic = {
    inherit family;
    style = "Italic";
  };

  bold_italic = {
    inherit family;
    style = overrides.${family}.bold_italic.style or "Bold Italic";
  };

  size = overrides.${family}.${machine}.size or default_size.${machine};
  offset.y = overrides.${family}.${machine}.offset.y or 0;
}
