{ font, colors }:

{
  config = {
    height = 20;
    spacing_left = 30;
    spacing_right = 40;
    text_font = ''"${font.text}"'';
    icon_font = ''"${font.icon}"'';
    background_color = colors.background;
    foreground_color = colors.foreground;
    space_icon_color = colors.space_icon;
    space_icon_strip = "1 2 3 4 5";
    power_icon_strip = "  ";
    clock_icon = " ";
    clock_format = ''"%a %d %b %R"'';
  };
}
