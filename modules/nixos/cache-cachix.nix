{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.caches.cachix;
in
{
  options.caches.cachix = {
    enable = mkEnableOption ''
      Enables the Cachix binary cache
    '';
  };
  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
