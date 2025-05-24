{ pkgs, ... }:

{
  name = "BlexMono Nerd Font";
  package = pkgs.nerd-fonts.blex-mono;
  size = _config: _program: 18.5;
}
