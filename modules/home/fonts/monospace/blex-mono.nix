{ config, pkgs, ... }:

{
  modules.fonts.monospace.blex-mono = {
    name = "BlexMono Nerd Font";
    package = pkgs.nerd-fonts.blex-mono;
    sizes = {
      default = 18.5;
      ghostty = if config.machines."skunk@linux".isCurrent then 14.0 else 18.5;
    };
  };
}
