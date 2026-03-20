{ pkgs, ... }:

{
  modules.fonts.sansSerif.iosevka-aile = {
    name = "Iosevka Aile";
    package = pkgs.iosevka-bin.override { variant = "Aile"; };
    sizes.default = 16.5;
  };
}
