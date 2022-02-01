{ colorscheme, font-family, palette, removePrefix }:

let
  colors = import ./colors.nix { inherit colorscheme palette; };
  font = import ./font.nix { family = font-family; };

  # Converts a color from hexadecimal to the format required by Spacebar.
  #
  # Example:
  #   toSpacebarFormat "#abb2bf" => "0xffabb2bf"
  toSpacebarFormat = color: "0xff" + (removePrefix "#" color);
in
{
  config = rec {
    height = 20;
    spacing_left = 30;
    spacing_right = 40;
    text_font = ''"${font.family}:${font.style}:${font.size}"'';
    icon_font = text_font;
    background_color = toSpacebarFormat colors.bg;
    foreground_color = toSpacebarFormat colors.fg;
    space_icon_color = toSpacebarFormat colors.focused-workspace-fg;
    space_icon_strip = "1 2 3 4 5";
    power_icon_strip = "  ";
    clock_icon = " ";
    clock_format = ''"%a %d %b %R"'';
  };
}
