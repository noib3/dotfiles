{ config, pkgs, ... }:

{
  modules.fonts.monospace.fira-code = {
    name = "FiraCode Nerd Font";
    package = pkgs.nerd-fonts.fira-code;
    sizes = {
      default = if config.machines."skunk@darwin".isCurrent then 18.5 else 13.5;
    };
  };
}
