{ pkgs, ... }:

{
  name = "BlexMono Nerd Font";
  package = pkgs.nerd-fonts.blex-mono;
  size =
    config: program:
    if program == "ghostty" && config.machines."skunk@linux".isCurrent then
      14.0
    else
      18.5;
}
