{ pkgs, ... }:

{
  name = "SourceCodePro Nerd Font";
  package = pkgs.nerd-fonts.sauce-code-pro;
  size =
    config: program:
    if program == "ghostty" && config.machines."skunk@linux".isCurrent then 14.0 else 16.5;
}
