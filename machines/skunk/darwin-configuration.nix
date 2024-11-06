{
  config,
  pkgs,
  colorscheme,
  hostName,
  ...
}:

let
  configDir = ../../configs;

  configs = import "${configDir}" {
    inherit (pkgs) lib;
    inherit colorscheme config pkgs;
    palette = import (../../palettes + "/${colorscheme}.nix");
  };
in
{
  imports = [
    ../../modules/darwin/desktop.nix
  ];

  modules.desktop = {
    enable = true;
    inherit hostName;
  };

  services = {
    inherit (configs) skhd yabai;
  };

  system.stateVersion = 5;
}
