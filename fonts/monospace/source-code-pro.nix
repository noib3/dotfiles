{ pkgs, ... }:

{
  name = "SourceCodePro Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "SourceCodePro" ]; };
  size = _config: _program: 16.5;
}
