{ family, machine }:

let
  f = {
    "FiraCode Nerd Font" = {
      bold_italic.style = "Bold";
      "blade".size = 9;
      "mbair".size = 19;
    };

    "Inconsolata Nerd Font" = {
      "blade".size = 11;
      "mbair".size = 19;
    };

    "Iosevka Nerd Font" = {
      "blade".size = 10;
      "mbair".size = 19;
    };

    "JetBrainsMono Nerd Font" = {
      bold.style = "Extra Bold";
      bold_italic.style = "Extra Bold";
      "blade".size = 9;
      "mbair".size = 19;
      "mbair".offset.y = 1;
      "mbair".glyph_offset.y = 1;
    };

    "Mononoki Nerd Font" = {
      bold_italic.style = "Bold";
      "blade".size = 10;
      "mbair".size = 19;
    };

    "RobotoMono Nerd Font" = {
      "blade".size = 10;
      "blade".offset.y = 1;
      "mbair".size = 19;
      "mbair".offset.y = 1;
    };
  };

  default_size = {
    "blade" = 10;
    "mbair" = 19;
  };
in
{
  normal = {
    inherit family;
    style = "Regular";
  };

  bold = {
    inherit family;
    style = f.${family}.bold.style or "Bold";
  };

  italic = {
    inherit family;
    style = "Italic";
  };

  bold_italic = {
    inherit family;
    style = f.${family}.bold_italic.style or "Bold Italic";
  };

  size = f.${family}.${machine}.size or default_size.${machine};
  offset.y = f.${family}.${machine}.offset.y or 0;
  glyph_offset.y = f.${family}.${machine}.glyph_offset.y or 0;
}
