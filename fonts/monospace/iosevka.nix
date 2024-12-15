{ pkgs, ... }:

{
  name = "Iosevka Nerd Font";
  package = pkgs.nerd-fonts.iosevka;
  size = _config: _program: 16.5;
}
