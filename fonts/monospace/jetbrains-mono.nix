{ pkgs, ... }:

{
  name = "JetBrainsMono Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  size = _config: _program: 16.5;
  bold = {
    name = "Extra Bold";
  };
  bold_italic = {
    name = "Extra Bold";
  };
}
