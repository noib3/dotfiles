{ pkgs, ... }:

{
  name = "FiraCode Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
  size = _config: _program: 13.5;
}
