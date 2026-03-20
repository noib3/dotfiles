{ pkgs, ... }:

{
  modules.fonts.serif.source-serif = {
    name = "Source Serif 4";
    package = pkgs.source-serif;
    sizes.default = 16.5;
  };
}
