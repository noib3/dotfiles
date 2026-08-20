{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.mpv;
in
{
  options.modules.mpv = {
    enable = mkEnableOption "mpv";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "mpv is only available on Linux";
      }
    ];

    programs.mpv = {
      enable = pkgs.stdenv.hostPlatform.isLinux;

      # See
      # https://raw.githubusercontent.com/mpv-player/mpv/master/etc/input.conf
      # for the full default config file containing all the possible actions.
      bindings = {
        k = "cycle sub down";
      };
    };
  };
}
