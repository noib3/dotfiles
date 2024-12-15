{ pkgs, ... }:

{
  name = "SourceCodePro Nerd Font";
  package = pkgs.nerd-fonts.sauce-code-pro;
  size = _config: _program: 16.5;
}
