{ pkgs, ... }:

{
  name = "FiraCode Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
  size = _config: _program: 16.5;
}
