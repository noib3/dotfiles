{ lib, font, colors }:

let
  # Converts a color from hexadecimal to the format required by Spacebar.
  #
  # Example:
  #   toSpacebarFormat "#abb2bf" => "0xffabb2bf"
  toSpacebarFormat = color: "0xff" + lib.strings.removePrefix "#" color;
in
{
  config = {
    height = 20;
    spacing_left = 30;
    spacing_right = 40;
    text_font = ''"${font.text}"'';
    icon_font = ''"${font.icons}"'';
    background_color = toSpacebarFormat colors.bg;
    foreground_color = toSpacebarFormat colors.fg;
    space_icon_color = toSpacebarFormat colors.focused-workspace-fg;
    space_icon_strip = "1 2 3 4 5";
    power_icon_strip = "  ";
    clock_icon = " ";
    clock_format = ''"%a %d %b %R"'';
  };
}
