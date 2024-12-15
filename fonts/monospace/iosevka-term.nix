{ pkgs, ... }:

{
  name = "Iosevka Term Nerd Font";
  package = pkgs.nerd-fonts.iosevka-term;
  size = _config: _program: 16.5;
}
