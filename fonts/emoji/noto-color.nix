{ pkgs, ... }:

{
  name = "Noto Color Emoji";
  package = pkgs.noto-fonts-emoji;
  size = _config: _program: 16.5;
}
