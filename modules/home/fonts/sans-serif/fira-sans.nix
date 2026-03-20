{ pkgs, ... }:

{
  modules.fonts.sansSerif.fira-sans = {
    name = "FiraSans";
    package = pkgs.fira-sans;
    sizes.default = 14.5;
  };
}
