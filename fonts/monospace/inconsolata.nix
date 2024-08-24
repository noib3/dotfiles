{ pkgs, ... }:

{
  name = "Inconsolata Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "Inconsolata" ]; };
  size = _config: _program: 16.5;
}
