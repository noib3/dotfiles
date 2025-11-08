{ pkgs, ... }:

{
  name = "Noto Color Emoji";
  package = pkgs.noto-fonts-color-emoji;
  size = _config: _program: 16.5;
}
