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

    # modules.macOSPreferences.domains."com.naotanhaocan.BetterMouse" = {
    # };
  };
}
