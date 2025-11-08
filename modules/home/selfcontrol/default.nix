{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.selfcontrol;
in
{
  options.modules.selfcontrol = {
    enable = mkEnableOption "SelfControl";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "SelfControl is only available on macOS";
      }
    ];

    home.packages = [
      pkgs.brewCasks.selfcontrol
    ];

    modules.defaults.CustomUserPreferences = {
      "org.eyebeam.SelfControl" =
        let
          oneDayInMinutes = 24 * 60;
        in
        {
          BlockLengthInterval = oneDayInMinutes;
          MaxBlockLength = oneDayInMinutes * 30;
        };
    };
  };
}
