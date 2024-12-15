{ pkgs, ... }:

{
  name = "Inconsolata Nerd Font";
  package = pkgs.nerd-fonts.inconsolata;
  size = _config: _program: 16.5;
}
