{ pkgs, ... }:

{
  modules.fonts.emoji.noto-color = {
    name = "Noto Color Emoji";
    package = pkgs.noto-fonts-color-emoji;
    sizes.default = 16.5;
  };
}
