{ pkgs, ... }:

{
  modules.fonts.monospace.inconsolata = {
    name = "Inconsolata Nerd Font";
    package = pkgs.nerd-fonts.inconsolata;
    sizes.default = 16.5;
  };
}
