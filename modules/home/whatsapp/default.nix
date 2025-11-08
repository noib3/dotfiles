{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.whatsapp;
in
{
  options.modules.whatsapp = {
    enable = mkEnableOption "WhatsApp desktop client";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "The WhatsApp desktop client is only available on macOS";
      }
    ];

    home.packages = [
      pkgs.brewCasks.whatsapp
    ];
  };
}
