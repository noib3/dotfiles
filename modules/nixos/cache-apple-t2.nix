{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.caches.apple-t2;
in
{
  options.caches.apple-t2 = {
    enable = mkEnableOption ''
      Enables the binary cache for Linux kernels with patches for Apple T2
      chips
    '';
  };
  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = [
        "https://cache.soopy.moe"
      ];
      trusted-public-keys = [
        "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      ];
    };
  };
}
