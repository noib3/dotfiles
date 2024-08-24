{ pkgs, ... }:

{
  name = "Iosevka Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
  size = _config: _program: 16.5;
}
