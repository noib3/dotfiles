{ pkgs, ... }:

{
  name = "FiraCode Nerd Font";
  package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
  size = config: _program: if config.machines."skunk@darwin".isCurrent then 18.5 else 13.5;
}
