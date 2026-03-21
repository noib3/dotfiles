{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.home-manager;
in
{
  options.modules.home-manager = {
    enable = mkEnableOption "Home Manager";
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;

    services.home-manager.autoExpire = {
      enable = true;
      frequency = "daily";
      timestamp = "-1 second"; # expire all but current
      store.cleanup = true; # run nix-collect-garbage after
    };
  };
}
