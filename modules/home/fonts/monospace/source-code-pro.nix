{ config, pkgs, ... }:

{
  modules.fonts.monospace.source-code-pro = {
    name = "SourceCodePro Nerd Font";
    package = pkgs.nerd-fonts.sauce-code-pro;
    sizes = {
      default = 16.5;
      ghostty = if config.machines."skunk@linux".isCurrent then 14.0 else 16.5;
    };
  };
}
