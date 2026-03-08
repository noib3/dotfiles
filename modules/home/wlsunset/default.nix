{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.wlsunset;
in
{
  options.modules.wlsunset = {
    enable = mkEnableOption "wlsunset";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "wlsunset is only available on Linux";
      }
    ];

    services.wlsunset = {
      enable = true;
      sunrise = "06:00";
      sunset = "22:00";
      temperature = {
        day = 6400;
        night = 3200;
      };
    };
  };
}
