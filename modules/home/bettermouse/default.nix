{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.bettermouse;
in
{
  options.modules.bettermouse = {
    enable = mkEnableOption "BetterMouse";

    autoUpdate = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to automatically check for updates";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "BetterMouse is only available on macOS";
      }
    ];

    home.packages = [
      pkgs.brewCasks.bettermouse
    ];

    modules.macOSPreferences.domains."com.naotanhaocan.BetterMouse" = {
      SUEnableAutomaticChecks = if cfg.autoUpdate then 1 else 0;
    };
  };
}
